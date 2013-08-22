# -*- encoding : utf-8 -*-
class Platform < ActiveRecord::Base
  VISIBILITIES = %w(open hidden)
  NAME_PATTERN = /[\w\-\.]+/

  READY                     = RepositoryStatus::READY
  WAITING_FOR_REGENERATION  = RepositoryStatus::WAITING_FOR_REGENERATION
  REGENERATING              = RepositoryStatus::REGENERATING

  HUMAN_STATUSES = {  READY                     => :ready,
                      WAITING_FOR_REGENERATION  => :waiting_for_regeneration,
                      REGENERATING              => :regenerating
                    }.freeze

  belongs_to :parent, :class_name => 'Platform', :foreign_key => 'parent_platform_id'
  belongs_to :owner, :polymorphic => true

  has_many :repositories, :dependent => :destroy
  has_many :products, :dependent => :destroy
  has_many :tokens, :as => :subject,  :dependent => :destroy
  has_many :platform_arch_settings,   :dependent => :destroy

  has_many :relations, :as => :target, :dependent => :destroy
  has_many :actors, :as => :target, :class_name => 'Relation', :dependent => :destroy
  has_many :members, :through => :actors, :source => :actor, :source_type => 'User'

  has_and_belongs_to_many :advisories

  has_many :packages, :class_name => "BuildList::Package", :dependent => :destroy

  has_many :mass_builds, :foreign_key => :save_to_platform_id

  validates :description, :presence => true
  validates :visibility, :presence => true, :inclusion => {:in => VISIBILITIES}
  validates :name, :uniqueness => {:case_sensitive => false}, :presence => true, :format => { :with => /\A#{NAME_PATTERN}\z/ }
  validates :distrib_type, :presence => true, :inclusion => {:in => APP_CONFIG['distr_types']}
  validate lambda {
    if released_was && !released
      errors.add(:released, I18n.t('flash.platform.released_status_can_not_be_changed'))
    end
  }
  validate lambda {
    if personal? && (owner_id_changed? || owner_type_changed?)
      errors.add :owner, I18n.t('flash.platform.owner_can_not_be_changed')
    end
  }, :on => :update

  before_create :create_directory
  before_destroy :detele_directory

  after_update :freeze_platform_and_update_repos
  after_update :update_owner_relation

  after_create lambda { symlink_directory unless hidden? }
  after_destroy lambda { remove_symlink_directory unless hidden? }

  scope :search_order, order("CHAR_LENGTH(#{table_name}.name) ASC")
  scope :search, lambda {|q| where("#{table_name}.name ILIKE ?", "%#{q.to_s.strip}%")}
  scope :by_visibilities, lambda {|v| where(:visibility => v)}
  scope :opened, where(:visibility => 'open')
  scope :hidden, where(:visibility => 'hidden')
  scope :by_type, lambda {|type| where(:platform_type => type) if type.present?}
  scope :main, by_type('main')
  scope :personal, by_type('personal')

  accepts_nested_attributes_for :platform_arch_settings, :allow_destroy => true
  attr_accessible :name, :distrib_type, :parent_platform_id, :platform_type, :owner, :visibility, :description, :released, :platform_arch_settings_attributes
  attr_readonly   :name, :distrib_type, :parent_platform_id, :platform_type

  include Modules::Models::Owner

  state_machine :status, :initial => :ready do
    event :ready do
      transition :regenerating => :ready
    end

    event :regenerate do
      transition :waiting_for_regeneration => :regenerating
      transition :ready => :waiting_for_regeneration
    end

    HUMAN_STATUSES.each do |code,name|
      state name, :value => code
    end
  end

  def clear
    system("rm -Rf #{ APP_CONFIG['root_path'] }/platforms/#{ self.name }/repository/*")
  end

  def urpmi_list(host = nil, pair = nil, add_commands = true, repository_name = 'main')
    host ||= default_host
    urpmi_commands = ActiveSupport::OrderedHash.new

    # TODO: rename method or create separate methods for mdv and rhel
    # Platform.main.opened.where(:distrib_type => APP_CONFIG['distr_types'].first).each do |pl|
    Platform.main.opened.each do |pl|
      urpmi_commands[pl.name] = {}
      # FIXME should support restricting access to the hidden platform
      Arch.all.each do |arch|
        tail = "/#{arch.name}/#{repository_name}/release"
        command = add_commands ? "urpmi.addmedia #{name} " : ''
        command << "#{APP_CONFIG['downloads_url']}/#{name}/repository/#{pl.name}#{tail}"
        urpmi_commands[pl.name][arch.name] = command
      end
    end

    return urpmi_commands
  end

  def path
    build_path(name)
  end

  def add_member(member, role = 'admin')
    Relation.add_member(member, self, role)
  end

  def remove_member(member)
    Relation.remove_member(member, self)
  end

  def symlink_path
    Rails.root.join("public", "downloads", name)
  end

  # Returns URL to repository, for example:
  # - http://abf-downloads.rosalinux.ru/rosa-server2012/repository/x86_64/base/
  # - http://abf-downloads.rosalinux.ru/uname_personal/repository/rosa-server2012/x86_64/base/
  def public_downloads_url(subplatform_name = nil, arch = nil, repo = nil)
    "#{APP_CONFIG['downloads_url']}/#{name}/repository/".tap do |url|
      url << "#{subplatform_name}/" if subplatform_name.present?
      url << "#{arch}/" if arch.present?
      url << "#{repo}/" if repo.present?
    end
  end

  def hidden?
    visibility == 'hidden'
  end

  def personal?
    platform_type == 'personal'
  end

  def main?
    platform_type == 'main'
  end

  def base_clone(attrs = {}) # :description, :name, :owner
    dup.tap do |c|
      attrs.each {|k,v| c.send("#{k}=", v)} # c.attributes = attrs
      c.updated_at = nil; c.created_at = nil
      c.parent = self; c.released = false
    end
  end

  def clone_relations(from = parent)
    self.repositories = from.repositories.map{|r| r.full_clone(:platform_id => id)}
    self.products     = from.products.map(&:full_clone)
  end

  def full_clone(attrs = {})
    base_clone(attrs).tap do |c|
      with_skip {c.save} and c.clone_relations(self) and c.fs_clone # later with resque
    end
  end

  def change_visibility
    if !hidden?
      update_attributes(:visibility => 'hidden')
    else
      update_attributes(:visibility => 'open')
    end
  end

  def symlink_directory
    # umount_directory_for_rsync # TODO ignore errors
    system("ln -s #{path} #{symlink_path}")
    Arch.all.each do |arch|
      str = "country=Russian Federation,city=Moscow,latitude=52.18,longitude=48.88,bw=1GB,version=2011,arch=#{arch.name},type=distrib,url=#{public_downloads_url}\n"
      File.open(File.join(symlink_path, "#{name}.#{arch.name}.list"), 'w') {|f| f.write(str) }
    end
  end

  def remove_symlink_directory
    system("rm -Rf #{symlink_path}")
  end

  def update_owner_relation
    if owner_id_was != owner_id
      r = relations.where(:actor_id => owner_id_was, :actor_type => owner_type_was).first
      r.update_attributes(:actor_id => owner_id, :actor_type => owner_type)
    end
  end

  def destroy
    with_skip {super} # avoid cascade XML RPC requests
  end
  later :destroy, :queue => :clone_build

  def default_host
    EventLog.current_controller.request.host_with_port rescue ::Rosa::Application.config.action_mailer.default_url_options[:host]
  end

  # Checks access rights to platform and caching for 1 day.
  def self.allowed?(path, request)
    platform_name = path.gsub(/^[\/]+/, '')
                        .match(/^(#{NAME_PATTERN}\/|#{NAME_PATTERN}$)/)

    return true unless platform_name
    platform_name = platform_name[0].gsub(/\//, '')

    if request.authorization.present?
      token, pass = *ActionController::HttpAuthentication::Basic::user_name_and_password(request)
    end

    Rails.cache.fetch([platform_name, token, :platform_allowed], :expires_in => 2.minutes) do
      platform = Platform.find_by_name platform_name
      next false  unless platform
      next true   unless platform.hidden?
      next false  unless token
      next true   if platform.tokens.by_active.where(:authentication_token => token).exists?

      user = User.find_by_authentication_token token
      current_ability = Ability.new(user)
      if user && current_ability.can?(:show, platform)
        true
      else
        false
      end
    end
  end

  protected

    def create_directory
      system("mkdir -p -m 0777 #{build_path([name, 'repository'])}")
    end


    def build_path(dir)
      File.join(APP_CONFIG['root_path'], 'platforms', dir)
    end

    def detele_directory
      FileUtils.rm_rf path
    end

    def fs_clone(old_name = parent.name, new_name = name)
      FileUtils.cp_r "#{parent.path}/repository", path
    end
    later :fs_clone, :queue => :clone_build

    def freeze_platform_and_update_repos
      if released_changed? && released == true
        repositories.update_all(:publish_without_qa => false)
      end
    end
end

class Platform < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: [:finders]

  include FileStoreClean
  include RegenerationStatus
  include Owner
  include EventLoggable
  include EmptyMetadata
  include DefaultBranchable
  include Platform::Finders

  self.per_page = 20

  CACHED_CHROOT_PRODUCT_NAME        = 'cached-chroot'
  AUTOMATIC_METADATA_REGENERATIONS  = %w(day week)
  VISIBILITIES                      = [
    VISIBILITY_OPEN   = 'open',
    VISIBILITY_HIDDEN = 'hidden'
  ]
  NAME_PATTERN                      = /[\w\-\.]+/
  HUMAN_STATUSES                    = HUMAN_STATUSES.clone.freeze
  TYPES                             = [
    TYPE_PERSONAL = 'personal',
    TYPE_MAIN     = 'main'
  ]

  belongs_to :parent, class_name: 'Platform', foreign_key: 'parent_platform_id'
  belongs_to :owner, polymorphic: true

  has_many :repositories, dependent: :destroy
  has_many :key_pairs, through: :repositories

  has_many :products, dependent: :destroy
  has_many :tokens, as: :subject, dependent: :destroy
  has_many :platform_arch_settings, dependent: :destroy
  has_many :repository_statuses

  has_many :relations, as: :target, dependent: :destroy
  has_many :actors, as: :target, class_name: 'Relation', dependent: :destroy
  has_many :members, through: :actors, source: :actor, source_type: 'User'


  has_and_belongs_to_many :advisories

  has_many :packages, class_name: "BuildList::Package", dependent: :destroy

  has_many :mass_builds, foreign_key: :save_to_platform_id

  validates :description,
    presence: true,
    length: { maximum: 10000 }

  validates :visibility,
    presence:   true,
    inclusion:  { in: VISIBILITIES }

  validates :platform_type,
    presence:   true,
    inclusion:  { in: TYPES }

  validates :automatic_metadata_regeneration,
    inclusion:    { in: AUTOMATIC_METADATA_REGENERATIONS },
    allow_blank:  true

  validates :name,
    uniqueness: { case_sensitive: false },
    presence:   true,
    format:     { with: /\A#{NAME_PATTERN}\z/ },
    length:     { maximum: 100 }

  validates :default_branch,
    presence:   true

  validates :distrib_type,
    presence:   true,
    inclusion:  { in: APP_CONFIG['distr_types'] }

  validate -> {
    if released_was && !released
      errors.add(:released, I18n.t('flash.platform.released_status_can_not_be_changed'))
    end
  }

  validate -> {
    if personal? && (owner_id_changed? || owner_type_changed?)
      errors.add :owner, I18n.t('flash.platform.owner_can_not_be_changed')
    end
  }, on: :update

  before_create :create_directory
  before_destroy :detele_directory

  after_update :freeze_platform_and_update_repos
  after_update :update_owner_relation

  after_create  -> { symlink_directory unless hidden? }
  after_destroy -> { remove_symlink_directory unless hidden? }

  accepts_nested_attributes_for :platform_arch_settings, allow_destroy: true
  # attr_accessible :name,
  #                 :distrib_type,
  #                 :parent_platform_id,
  #                 :platform_type,
  #                 :owner,
  #                 :visibility,
  #                 :description,
  #                 :released,
  #                 :platform_arch_settings_attributes,
  #                 :automatic_metadata_regeneration,
  #                 :admin_id,
  #                 :term

  attr_accessor :admin_id, :term

  attr_readonly :name, :distrib_type, :parent_platform_id, :platform_type

  state_machine :status, initial: :ready do

    after_transition on: :ready, do: :notify_users

    event :ready do
      transition regenerating: :ready
    end

    event :regenerate do
      transition ready: :waiting_for_regeneration, if: ->(p) { p.main? }
    end

    event :start_regeneration do
      transition waiting_for_regeneration: :regenerating
    end

    HUMAN_STATUSES.each do |code,name|
      state name, value: code
    end
  end

  def clear
    system("rm -Rf #{ APP_CONFIG['root_path'] }/platforms/#{ self.name }/repository/*")
  end

  def urpmi_list(host = nil, pair = nil, add_commands = true, repository_name = 'main')
    host ||= default_host
    urpmi_commands = ActiveSupport::OrderedHash.new

    # TODO: rename method or create separate methods for mdv and rhel
    # Platform.main.opened.where(distrib_type: APP_CONFIG['distr_types'].first).each do |pl|
    arches = Arch.all.to_a
    Platform.main.opened.each do |pl|
      urpmi_commands[pl.name] = {}
      # FIXME should support restricting access to the hidden platform
      arches.each do |arch|
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
    visibility == VISIBILITY_HIDDEN
  end

  def personal?
    platform_type == TYPE_PERSONAL
  end

  def main?
    platform_type == TYPE_MAIN
  end

  def base_clone(attrs = {}) # :description, :name, :owner
    dup.tap do |c|
      attrs.each {|k,v| c.send("#{k}=", v)} # c.attributes = attrs
      c.updated_at = nil; c.created_at = nil
      c.parent = self; c.released = false
    end
  end

  def clone_relations(from = parent)
    self.repositories = from.repositories.map{|r| r.full_clone(platform_id: id)}
    self.products     = from.products.map(&:full_clone)
  end

  def full_clone(attrs = {})
    base_clone(attrs).tap do |c|
      with_skip {c.save} and c.clone_relations(self) and c.fs_clone # later with resque
    end
  end

  def change_visibility
    if hidden?
      update_attributes(visibility: VISIBILITY_OPEN)
    else
      update_attributes(visibility: VISIBILITY_HIDDEN)
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
  later :symlink_directory, queue: :middle

  def remove_symlink_directory
    system("rm -Rf #{symlink_path}")
  end

  def update_owner_relation
    if owner_id_was != owner_id
      r = relations.where(actor_id: owner_id_was, actor_type: owner_type_was).first
      r.update_attributes(actor_id: owner_id, actor_type: owner_type)
    end
  end

  def destroy
    with_skip {super} # avoid cascade XML RPC requests
  end
  later :destroy, queue: :low

  def default_host
    EventLog.current_controller.request.host_with_port rescue ::Rosa::Application.config.action_mailer.default_url_options[:host]
  end

  # Checks access rights to platform and caching for 1 day.
  def self.allowed?(path, token)
    platform_name = path.gsub(/^[\/]+/, '')
                        .match(/^(#{NAME_PATTERN}\/|#{NAME_PATTERN}$)/)

    return true unless platform_name
    platform_name = platform_name[0].gsub(/\//, '')

    Rails.cache.fetch([platform_name, token, :platform_allowed], expires_in: 2.minutes) do
      platform = Platform.find_by name: platform_name
      next false  unless platform
      next true   unless platform.hidden?
      return false  if token.blank?
      return true   if platform.tokens.by_active.where(authentication_token: token).exists?
      user = User.find_by(authentication_token: token)
      !!(user && PlatformPolicy.new(user, platform).show?)
    end
  end

  def cached_chroot(arch)
    return false if personal?
    Rails.cache.fetch([:cached_chroot, name, arch], expires_in: 10.minutes) do
      product = products.where(name: CACHED_CHROOT_PRODUCT_NAME).first
      next false unless product
      pbl = product.product_build_lists.for_status(ProductBuildList::BUILD_COMPLETED).recent.first
      next false unless pbl
      result = pbl.results.find{ |r| r['file_name'] =~ /-#{arch}.tar.gz$/ }
      result.present? ? result['sha1'] : false
    end
  end

  def self.autostart_metadata_regeneration(value)
    Platform.main.where(automatic_metadata_regeneration: value).each(&:regenerate)
  end

  def self.availables_main_platforms(user)
    p_ids = Rails.cache.fetch([:availables_main_platforms, user], expires_in: 10.minutes) do
      PlatformPolicy::Scope.new(user, Platform).show.main.joins(:repositories).
        where('repositories.id IS NOT NULL').uniq.pluck(:id)
    end
    Platform.preload(:repositories).where(id: p_ids).order(:name)
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
    later :fs_clone, queue: :low

    def freeze_platform_and_update_repos
      if released_changed? && released == true
        repositories.update_all(publish_without_qa: false)
      end
    end

    def notify_users
      users = members.includes(:notifier).select{ |u| u.notifier.can_notify? }
      users.each{ |u| UserMailer.metadata_regeneration_notification(self, u).deliver }
    end

end

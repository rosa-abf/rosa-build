# -*- encoding : utf-8 -*-
class Project < ActiveRecord::Base
  VISIBILITIES = ['open', 'hidden']
  MAX_OWN_PROJECTS = 32000
  NAME_REGEXP = /[a-zA-Z0-9_\-\+\.]+/

  belongs_to :owner, :polymorphic => true, :counter_cache => :own_projects_count
  belongs_to :maintainer, :class_name => "User"

  has_many :issues, :dependent => :destroy
  has_many :pull_requests, :dependent => :destroy, :foreign_key => 'to_project_id'
  has_many :labels, :dependent => :destroy
  has_many :build_lists, :dependent => :destroy

  has_many :project_imports, :dependent => :destroy
  has_many :project_to_repositories, :dependent => :destroy
  has_many :repositories, :through => :project_to_repositories

  has_many :relations, :as => :target, :dependent => :destroy
  has_many :collaborators, :through => :relations, :source => :actor, :source_type => 'User'
  has_many :groups,        :through => :relations, :source => :actor, :source_type => 'Group'

  has_many :packages, :class_name => "BuildList::Package", :dependent => :destroy
  has_and_belongs_to_many :advisories # should be without :dependent => :destroy

  validates :name, :uniqueness => {:scope => [:owner_id, :owner_type], :case_sensitive => false},
                   :presence => true,
                   :format => {:with => /\A#{NAME_REGEXP}\z/, :message => I18n.t("activerecord.errors.project.uname")}
  validates :owner, :presence => true
  validates :maintainer_id, :presence => true, :unless => :new_record?
  validates :visibility, :presence => true, :inclusion => {:in => VISIBILITIES}
  validate { errors.add(:base, :can_have_less_or_equal, :count => MAX_OWN_PROJECTS) if owner.projects.size >= MAX_OWN_PROJECTS }
  validate :check_default_branch

  attr_accessible :name, :description, :visibility, :srpm, :is_package, :default_branch, :has_issues, :has_wiki, :maintainer_id
  attr_readonly :name, :owner_id, :owner_type

  scope :recent, order("name ASC")
  scope :search_order, order("CHAR_LENGTH(name) ASC")
  scope :search, lambda {|q| by_name("%#{q.to_s.strip}%")}
  scope :by_name, lambda {|name| where('projects.name ILIKE ?', name) if name.present?}
  scope :by_visibilities, lambda {|v| where(:visibility => v)}
  scope :opened, where(:visibility => 'open')
  scope :package, where(:is_package => true)
  scope :addable_to_repository, lambda { |repository_id| where %Q(
    projects.id NOT IN (
      SELECT
        ptr.project_id
      FROM
        project_to_repositories AS ptr
      WHERE (ptr.repository_id = #{ repository_id })
    )
  ) }
  scope :by_owners, lambda { |group_owner_ids, user_owner_ids|
    where("(projects.owner_id in (?) AND projects.owner_type = 'Group') OR (projects.owner_id in (?) AND projects.owner_type = 'User')", group_owner_ids, user_owner_ids)
  }

  before_validation :truncate_name, :on => :create
  before_create :set_maintainer
  after_save :attach_to_personal_repository
  after_update :set_new_git_head

  has_ancestry :orphan_strategy => :rootify #:adopt not available yet

  include Modules::Models::Owner
  include Modules::Models::Git
  include Modules::Models::Wiki

  class << self
    def find_by_owner_and_name(owner_name, project_name)
      owner = User.find_by_uname(owner_name) || Group.find_by_uname(owner_name) || User.by_uname(owner_name).first || Group.by_uname(owner_name).first and
      scoped = where(:owner_id => owner.id, :owner_type => owner.class) and
      scoped.find_by_name(project_name) || scoped.by_name(project_name).first
      # owner.projects.find_by_name(project_name) || owner.projects.by_name(project_name).first # TODO force this work?
    end

    def find_by_owner_and_name!(owner_name, project_name)
      find_by_owner_and_name(owner_name, project_name) or raise ActiveRecord::RecordNotFound
    end
  end

  def to_param
    name
  end

  def all_members
    members | (owner_type == 'User' ? [owner] : owner.members)
  end

  def members
    collaborators | groups.map(&:members).flatten
  end

  def add_member(member, role = 'admin')
    Relation.add_member(member, self, role)
  end

  def remove_member(member)
    Relation.remove_member(member, self)
  end

  def platforms
    @platforms ||= repositories.map(&:platform).uniq
  end

  def owner_and_admin_ids
    recipients = self.relations.by_role('admin').where(:actor_type => 'User').map { |rel| rel.read_attribute(:actor_id) }
    recipients = recipients | [self.owner_id] if self.owner_type == 'User'
    recipients
  end

  def public?
    visibility == 'open'
  end

  def owner?(user)
    owner == user
  end

  def git_project_address auth_user
    host ||= EventLog.current_controller.request.host_with_port rescue ::Rosa::Application.config.action_mailer.default_url_options[:host]
    protocol = APP_CONFIG['mailer_https_url'] ? "https" : "http" rescue "http"
    opts = {:host => host, :protocol => protocol, :user => auth_user.authentication_token, :password => ''}
    Rails.application.routes.url_helpers.project_url(self.owner.uname, self.name, opts) + ".git"
    #path #share by NFS
  end

  def build_for(platform, repository_id, user, arch =  Arch.find_by_name('i586'), auto_publish = false, mass_build_id = nil, priority = 0)
    # Select main and project platform repository(contrib, non-free and etc)
    # If main does not exist, will connect only project platform repository
    # If project platform repository is main, only main will be connect
    main_rep_id = platform.repositories.find_by_name('main').try(:id)
    build_reps_ids = [main_rep_id, repository_id].compact.uniq

    build_lists.create do |bl|
      bl.save_to_platform = platform
      bl.build_for_platform = platform
      bl.update_type = 'newpackage'
      bl.arch = arch
      bl.project_version = "latest_#{platform.name}"
      bl.build_requires = false # already set as db default
      bl.user = user
      bl.auto_publish = auto_publish
      bl.include_repos = build_reps_ids
      bl.priority = priority
      bl.mass_build_id = mass_build_id
      bl.save_to_repository_id = repository_id
    end
  end

  def fork(new_owner)
    dup.tap do |c|
      c.parent_id = id
      c.owner = new_owner
      c.updated_at = nil; c.created_at = nil # :id = nil
      # Hack to call protected method :)
      c.send :set_maintainer
      c.save
    end
  end

  def human_average_build_time
    I18n.t("layout.projects.human_average_build_time", {:hours => (average_build_time/3600).to_i, :minutes => (average_build_time%3600/60).to_i})
  end

  def formatted_average_build_time
    "%02d:%02d" % [average_build_time / 3600, average_build_time % 3600 / 60]
  end

  def xml_rpc_create(repository)
    result = BuildServer.create_project name, repository.platform.name, repository.name, path
    if result == BuildServer::SUCCESS
      return true
    else
      raise "Failed to create project #{name} (repo #{repository.name}) inside platform #{repository.platform.name} in path #{path} with code #{result}."
    end
  end

  def xml_rpc_destroy(repository)
    result = BuildServer.delete_project name, repository.platform.name
    if result == BuildServer::SUCCESS
      return true
    else
      raise "Failed to delete repository #{name} (repo main) inside platform #{owner.uname}_personal with code #{result}."
    end
  end

  protected

  def truncate_name
    self.name = name.strip if name
  end

  def attach_to_personal_repository
    owner_rep = self.owner.personal_repository
    if is_package
      repositories << owner_rep unless repositories.exists?(:id => owner_rep)
    else
      repositories.delete owner_rep
    end
  end

  def set_maintainer
    if maintainer_id.blank?
      self.maintainer_id = (owner_type == 'User') ? self.owner_id : self.owner.owner_id
    end
  end

  def set_new_git_head
    `cd #{path} && git symbolic-ref HEAD refs/heads/#{self.default_branch}` if self.default_branch_changed? && self.repo.branches.map(&:name).include?(self.default_branch)
  end

  def check_default_branch
    if self.repo.branches.count > 0 && self.repo.branches.map(&:name).exclude?(self.default_branch)
      errors.add :default_branch, I18n.t('activerecord.errors.project.default_branch')
    end
  end
end

class Project < ActiveRecord::Base
  VISIBILITIES = ['open', 'hidden']

  relationable :as => :target

  belongs_to :category, :counter_cache => true
  belongs_to :owner, :polymorphic => true

  has_many :build_lists, :dependent => :destroy

  has_many :project_to_repositories, :dependent => :destroy
  has_many :repositories, :through => :project_to_repositories

  has_many :relations, :as => :target, :dependent => :destroy
  has_many :collaborators, :through => :relations, :source => :object, :source_type => 'User'
  has_many :groups,        :through => :relations, :source => :object, :source_type => 'Group'

  validates :name,     :uniqueness => {:scope => [:owner_id, :owner_type]}, :presence => true, :allow_nil => false, :allow_blank => false
  validates :unixname, :uniqueness => {:scope => [:owner_id, :owner_type]}, :presence => true, :format => { :with => /^[a-zA-Z0-9_]+$/ }, :allow_nil => false, :allow_blank => false
  validates :owner, :presence => true
  validate {errors.add(:base, I18n.t('flash.project.save_warning_ssh_key')) if owner.ssh_key.blank?}

  attr_accessible :category_id, :name, :unixname, :description, :visibility
  attr_readonly :unixname

  scope :recent, order("name ASC")
  scope :by_name, lambda { |name| {:conditions => ['name like ?', '%' + name + '%']} }
  scope :by_visibilities, lambda {|v| {:conditions => ['visibility in (?)', v.join(',')]}}
  scope :addable_to_repository, lambda { |repository_id| where("projects.id NOT IN (SELECT project_to_repositories.project_id FROM project_to_repositories WHERE (project_to_repositories.repository_id != #{ repository_id }))") }

  before_create :create_git_repo, :make_owner_rel
  before_update :update_git_repo
  before_destroy :destroy_git_repo
  before_create :xml_rpc_create
  before_destroy :xml_rpc_destroy
  after_create :attach_to_personal_repository

  def project_versions
    self.git_repository.tags
  end

  def members
    collaborators + groups
  end

  include Project::HasRepository
  # Redefining a method from Project::HasRepository module to reflect current situation
  def git_repo_path
    @git_repo_path ||= path
  end
  def git_repo_name
    [owner.uname, unixname].join('/')
  end
  def git_repo_name_was
    [owner.uname, unixname_was].join('/')
  end
  def git_repo_name_changed?; git_repo_name != git_repo_name_was; end

  def public?
    visibility == 'open'
  end

  def clone
    p = Project.new
    p.name = name
    p.unixname = unixname
    return p
  end

  def add_to_repository(platf, repo)
    result = BuildServer.add_to_repo(repository.name, platf.name)
    if result == BuildServer::SUCCESS
      return true
    else
      raise "Failed to add project #{name} to repo #{repo.name} of platform #{platf.name}."
    end      
  end

  def path
    build_path(git_repo_name)
  end

  def xml_rpc_create
    result = BuildServer.create_project unixname, repository.platform.unixname, repository.unixname
    if result == BuildServer::SUCCESS
      return true
    else
      raise "Failed to create project #{name} (repo #{repository.name}) inside platform #{repository.platform.name}."
    end      
  end

  protected

    def build_path(dir)
      File.join(APP_CONFIG['root_path'], 'git_projects', "#{dir}.git")
    end

    def attach_to_personal_repository
      repositories << self.owner.personal_repository if !repositories.exists?(:id => self.owner.personal_repository)
    end

    def make_owner_rel
      unless groups.include? owner or collaborators.include? owner
        collaborators << owner if owner.instance_of? User
        groups        << owner if owner.instance_of? Group
      end
    end

    def create_git_repo
      with_ga do |ga|
        repo = ga.add_repo git_repo_name
        repo.add_key owner.ssh_key, 'RW'
        repo.has_anonymous_access!('R') if public?
        ga.save_and_release
      end
    end

    def update_git_repo
      with_ga do |ga|
        if repo = ga.find_repo(git_repo_name_was)
          repo.rename(git_repo_name) if git_repo_name_changed?
          public? ? repo.has_anonymous_access!('R') : repo.has_not_anonymous_access!
          ga.save_and_release
        end
      end if git_repo_name_changed? or visibility_changed?
    end

    def destroy_git_repo
      with_ga do |ga|
        ga.rm_repo git_repo_name
        ga.save_and_release
      end
    end

    def xml_rpc_create
      result = BuildServer.create_project unixname,  "#{owner.uname}_personal", 'main'
      if result == BuildServer::SUCCESS
        return true
      else
        raise "Failed to create project #{name} (repo main) inside platform #{owner.uname}_personal."
      end      
    end

    def xml_rpc_destroy
      result = BuildServer.delete_project unixname, "#{owner.uname}_personal"
      if result == BuildServer::SUCCESS
        return true
      else
        raise "Failed to delete repository #{name} (repo main) inside platform #{owner.uname}_personal."
      end
    end
end

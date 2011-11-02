class Project < ActiveRecord::Base
  VISIBILITIES = ['open', 'hidden']

  relationable :as => :target

  belongs_to :category, :counter_cache => true
  belongs_to :owner, :polymorphic => true

  has_many :build_lists, :dependent => :destroy
  has_many :auto_build_lists, :dependent => :destroy

  has_many :project_to_repositories, :dependent => :destroy
  has_many :repositories, :through => :project_to_repositories

  has_many :relations, :as => :target, :dependent => :destroy
  has_many :collaborators, :through => :relations, :source => :object, :source_type => 'User'
  has_many :groups,        :through => :relations, :source => :object, :source_type => 'Group'
  has_many :auto_build_lists, :dependent => :destroy

  validates :name,     :uniqueness => {:scope => [:owner_id, :owner_type]}, :presence => true, :allow_nil => false, :allow_blank => false
  validates :unixname, :uniqueness => {:scope => [:owner_id, :owner_type]}, :presence => true, :format => { :with => /^[a-zA-Z0-9_\-\+\.]+$/ }, :allow_nil => false, :allow_blank => false
  validates :owner, :presence => true
  validate {errors.add(:base, I18n.t('flash.project.save_warning_ssh_key')) if owner.ssh_key.blank?}

  #attr_accessible :category_id, :name, :unixname, :description, :visibility
  attr_readonly :unixname

  scope :recent, order("name ASC")
#  scope :by_name, lambda { |name| {:conditions => ['name like ?', '%' + name + '%']} }
  scope :by_name, lambda { |name| where('name like ?', '%' + name + '%') }
  scope :by_visibilities, lambda {|v| {:conditions => ['visibility in (?)', v.join(',')]}}
  scope :addable_to_repository, lambda { |repository_id| where("projects.id NOT IN (SELECT project_to_repositories.project_id FROM project_to_repositories WHERE (project_to_repositories.repository_id = #{ repository_id }))") }
  scope :automateable, where("projects.id NOT IN (SELECT auto_build_lists.project_id FROM auto_build_lists)")

 # before_save :add_owner_rel
  after_create :make_owner_rel
  before_save :check_owner_rel

  after_create :attach_to_personal_repository
  after_create :create_git_repo
  before_update :update_git_repo
  after_destroy :destroy_git_repo
  after_rollback lambda { destroy_git_repo rescue true if new_record? }

  def project_versions
    res = tags.select { |tag| tag.name =~ /^v\./  }
    return res if res and res.size > 0
    tags
  end
  
  def collected_project_versions
    project_versions.collect { |tag| new_tag = tag.name.gsub(/^\w+\./, ""); [new_tag, new_tag] }
  end

  def tags
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
      raise "Failed to add project #{name} to repo #{repo.name} of platform #{platf.name} with code #{result}."
    end      
  end

  def path
    build_path(git_repo_name)
  end

  def xml_rpc_create(repository)
    result = BuildServer.create_project unixname, repository.platform.unixname, repository.unixname, path
    if result == BuildServer::SUCCESS
      return true
    else
      raise "Failed to create project #{unixname} (repo #{repository.unixname}) inside platform #{repository.platform.unixname} in path #{path} with code #{result}."
    end      
  end

  def xml_rpc_destroy(repository)
    result = BuildServer.delete_project unixname, repository.platform.unixname
    if result == BuildServer::SUCCESS
      return true
    else
      raise "Failed to delete repository #{name} (repo main) inside platform #{owner.uname}_personal with code #{result}."
    end
  end

  protected

    def build_path(dir)
      File.join(APP_CONFIG['root_path'], 'git_projects', "#{dir}.git")
    end

    def attach_to_personal_repository
      repositories << self.owner.personal_repository if !repositories.exists?(:id => self.owner.personal_repository)
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

    def add_owner_rel
      if new_record? and owner
        add_owner owner
      elsif owner_id_changed?
        remove_owner owner_type_was.classify.find(owner_id_was)
        add_owner owner
      end
    end

    def make_owner_rel
      add_owner owner
    end

    def check_owner_rel
      if !new_record? and owner_id_changed?
        remove_owner owner_type_was.classify.find(owner_id_was) if owner_type_was
        add_owner owner if owner
      end
    end

end

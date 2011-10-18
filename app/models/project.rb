class Project < ActiveRecord::Base
  belongs_to :owner, :polymorphic => true

  has_many :build_lists, :dependent => :destroy

  has_many :project_to_repositories
  has_many :repositories, :through => :project_to_repositories

  has_many :relations, :as => :target
  has_many :collaborators, :through => :relations, :source => :object, :source_type => 'User'
  has_many :groups,        :through => :relations, :source => :object, :source_type => 'Group'

  validates :name,     :uniqueness => {:scope => [:owner_id, :owner_type]}, :presence => true, :allow_nil => false, :allow_blank => false
  validates :unixname, :uniqueness => {:scope => [:owner_id, :owner_type]}, :presence => true, :format => { :with => /^[a-zA-Z0-9_]+$/ }, :allow_nil => false, :allow_blank => false
#  validates :unixname, :uniqueness => {:scope => [:owner_id, :owner_type]}, :presence => true, :format => { :with => /^[a-zA-Z0-9\-.]+$/ }, :allow_nil => false, :allow_blank => false

  include Project::HasRepository

  scope :recent, order("name ASC")
  scope :by_name, lambda { |name| {:conditions => ['name like ?', '%' + name + '%']} }

  after_create :make_owner_rel
  #before_create :create_directory, :create_git_repo
#  before_create :xml_rpc_create
#  before_destroy :xml_rpc_destroy

  def members
    collaborators + groups
  end

  # Redefining a method from Project::HasRepository module to reflect current situation
  def git_repo_path
    @git_repo_path ||= File.join(repository.platform.path, "projects", unixname + ".git")
  end

  def path
    build_path(unixname)
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

  protected

    def make_owner_rel
      collaborators << owner if owner.instance_of? User
      groups        << owner if owner.instance_of? Group
      save
    end

    def build_path(dir)
      File.join(repository.path, dir)
    end

    def create_directory
      exists = File.exists?(path) && File.directory?(path)
      raise "Directory #{path} already exists" if exists
      if new_record?
        FileUtils.mkdir_p(path)
      elsif unixname_changed?
        FileUtils.mv(build_path(unixname_was), buildpath(unixname))
      end 
    end

    def xml_rpc_create
      result = BuildServer.create_project unixname, repository.platform.unixname, repository.unixname
      if result == BuildServer::SUCCESS
        return true
      else
        raise "Failed to create project #{name} (repo #{repository.name}) inside platform #{repository.platform.name}."
      end      
    end

    def xml_rpc_destroy
      result = BuildServer.delete_project unixname, repository.platform.unixname
      if result == BuildServer::SUCCESS
        return true
      else
        raise "Failed to delete repository #{name} (repo #{repository.name}) inside platform #{repository.platform.name}."
      end
    end
end

class Repository < ActiveRecord::Base
  belongs_to :platform
  belongs_to :owner, :polymorphic => true

  has_many :projects, :through => :project_to_repositories #, :dependent => :destroy
  has_many :project_to_repositories

  has_many :objects, :as => :target, :class_name => 'Relation'
  has_many :members, :through => :objects, :source => :object, :source_type => 'User'
  has_many :groups,  :through => :objects, :source => :object, :source_type => 'Group'

  validates :name, :uniqueness => {:scope => [:owner_id, :owner_type]}, :presence => true
  validates :unixname, :uniqueness => {:scope => [:owner_id, :owner_type]}, :presence => true, :format => { :with => /^[a-zA-Z0-9\-.]+$/ }
  validates :platform_id, :presence => true

  scope :recent, order("name ASC")

  after_create :make_owner_rel

#  before_create :xml_rpc_create
#  before_destroy :xml_rpc_destroy

  def path
    build_path(unixname)
  end

  def clone
    r = Repository.new
    r.name = name
    r.unixname = unixname
    r.projects = projects.map(&:clone)
    return r
  end

  protected

    def make_owner_rel
      members << owner if owner.instance_of? User
      groups  << owner if owner.instance_of? Group
      save
    end

    def build_path(dir)
      File.join(platform.path, dir)
    end

    def create_directory
      exists = File.exists?(path) && File.directory?(path)
      raise "Directory #{path} already exists" if exists
      if new_record?
        FileUtils.mkdir_p(path)
        %w(release updates).each { |subrep| FileUtils.mkdir_p(path + subrep) }
      elsif unixname_changed?
        FileUtils.mv(build_path(unixname_was), buildpath(unixname))
      end 
    end
    
    def xml_rpc_create
      result = BuildServer.create_repo unixname, platform.unixname
      if result == BuildServer::SUCCESS
        return true
      else
        raise "Failed to create repository #{name} inside platform #{platform.name}."
      end      
    end

    def xml_rpc_destroy
      result = BuildServer.delete_repo unixname, platform.unixname
      if result == BuildServer::SUCCESS
        return true
      else
        raise "Failed to delete repository #{name} inside platform #{platform.name}."
      end
    end

end

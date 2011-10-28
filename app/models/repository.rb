class Repository < ActiveRecord::Base

  VISIBILITIES = ['open', 'hidden']
  relationable :as => :target

  belongs_to :platform
  belongs_to :owner, :polymorphic => true

  has_many :projects, :through => :project_to_repositories #, :dependent => :destroy
  has_many :project_to_repositories, :validate => true

  has_many :objects, :as => :target, :class_name => 'Relation'
  has_many :members, :through => :objects, :source => :object, :source_type => 'User'
  has_many :groups,  :through => :objects, :source => :object, :source_type => 'Group'

  validates :name, :uniqueness => {:scope => :platform_id}, :presence => true
  validates :unixname, :uniqueness => {:scope => :platform_id}, :presence => true, :format => { :with => /^[a-zA-Z0-9\-.]+$/ }
  validates :platform_id, :presence => true

  scope :recent, order("name ASC")
  scope :by_visibilities, lambda {|v| {:conditions => ['visibility in (?)', v.join(',')]}}

  #before_save :create_directory
  before_save :make_owner_rel
  #after_destroy :remove_directory

  before_create :xml_rpc_create
  before_destroy :xml_rpc_destroy

  attr_accessible :visibility, :name, :unixname, :platform_id
  
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
      unless members.include? owner
        members << owner if owner.instance_of? User
        groups  << owner if owner.instance_of? Group
      end
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

    def remove_directory
      exists = File.exists?(path) && File.directory?(path)
      raise "Directory #{path} didn't exists" unless exists
      FileUtils.rm_rf(path)
    end

    def xml_rpc_create
      result = BuildServer.create_repo unixname, platform.unixname
      if result == BuildServer::SUCCESS
        return true
      else
        raise "Failed to create repository #{name} inside platform #{platform.name} with code #{result}."
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

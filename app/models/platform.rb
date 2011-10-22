#require 'lib/build_server.rb'
class Platform < ActiveRecord::Base
  belongs_to :parent, :class_name => 'Platform', :foreign_key => 'parent_platform_id'
  belongs_to :owner, :polymorphic => true

  has_many :repositories, :dependent => :destroy
  has_many :products, :dependent => :destroy

  has_many :objects, :as => :target, :class_name => 'Relation'
  has_many :members, :through => :objects, :source => :object, :source_type => 'User'
  has_many :groups,  :through => :objects, :source => :object, :source_type => 'Group'

  validates :name, :presence => true, :uniqueness => true
  validates :unixname, :uniqueness => true, :presence => true, :format => { :with => /^[a-zA-Z0-9_]+$/ }, :allow_nil => false, :allow_blank => false

  #after_create :make_owner_rel
  before_save :create_directory
  before_save :make_owner_rel
  after_destroy :remove_directory
#  before_create :xml_rpc_create
#  before_destroy :xml_rpc_destroy
#  before_update :check_freezing

  scope :main, where(:platform_type => 'main')

  def path
    build_path(unixname)
  end

  def clone(new_name, new_unixname)
    p = Platform.new
    p.name = new_name
    p.unixname = new_unixname
    p.parent = self
    p.repositories = repositories.map(&:clone)
    result = p.save
    return (result && xml_rpc_clone(new_unixname) && p)
  end

  def name
    released? ? "#{self[:name]} #{I18n.t("layout.platforms.released_suffix")}" : self[:name]
  end

  def roles_of(user)
    objects.where(:object_id => user.id, :object_type => user.class).map {|rel| rel.role}.reject {|r| r.nil?}
  end

  def add_role(user, role)
    roles = objects.where(:object_id => user.id, :object_type => user.class).map {|rel| rel.role}.reject {|r| r.nil?}
    unless roles.include? role
      rel = Relation.create(:object_type => user.class.to_s, :object_id => user.id,
                            :target_type => self.class.to_s, :target_id => id)
      rel.role = role
      rel.save
    end
  end

  protected

    def build_path(dir)
      File.join(APP_CONFIG['root_path'], 'platforms', dir)
    end

    def git_path(dir)
      File.join(build_path(dir), 'git')
    end

    def create_directory
      exists = File.exists?(path) && File.directory?(path)
      raise "Directory #{path} already exists" if exists
      if new_record?
        FileUtils.mkdir_p(path)
      elsif unixname_changed?
        FileUtils.mv(build_path(unixname_was), build_path(unixname))
      end 
    end

    def remove_directory
      exists = File.exists?(path) && File.directory?(path)
      raise "Directory #{path} didn't exists" unless exists
      FileUtils.rm_rf(path)
    end

    def make_owner_rel
      unless members.include? owner or groups.include? owner
        members << owner if owner.instance_of? User
        groups  << owner if owner.instance_of? Group
      end
    end

    def xml_rpc_create
      return true
#      result = BuildServer.add_platform unixname, APP_CONFIG['root_path']
#      if result == BuildServer::SUCCESS
#        return true
#      else
#        raise "Failed to create platform #{name}. Path: #{build_path(unixname)}"
#      end
    end

    def xml_rpc_destroy
      return true
#      result = BuildServer.delete_platform unixname
#      if result == BuildServer::SUCCESS
#        return true
#      else
#        raise "Failed to delete platform #{unixname}."
#      end
    end

    def xml_rpc_clone(new_unixname)
      return true
#      result = BuildServer.clone_platform new_unixname, self.unixname, APP_CONFIG['root_path']
#      if result == BuildServer::SUCCESS
#        return true
#      else
#        raise "Failed to clone platform #{name}. Path: #{build_path(unixname)} to platform #{new_unixname}"
#      end
    end

    def check_freezing
      if released_changed?
        BuildServer.freeze_platform self.unixname
      end
    end
end

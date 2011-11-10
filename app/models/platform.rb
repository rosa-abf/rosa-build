#require 'lib/build_server.rb'
class Platform < ActiveRecord::Base
  DOWNLOADS_PATH = RAILS_ROOT + '/public/downloads'
  VISIBILITIES = ['open', 'hidden']
  
  relationable :as => :target

  belongs_to :parent, :class_name => 'Platform', :foreign_key => 'parent_platform_id'
  belongs_to :owner, :polymorphic => true

  has_many :repositories, :dependent => :destroy
  has_many :products, :dependent => :destroy

  has_many :objects, :as => :target, :class_name => 'Relation', :dependent => :destroy
  has_many :members, :through => :objects, :source => :object, :source_type => 'User'
  has_many :groups,  :through => :objects, :source => :object, :source_type => 'Group'

  validates :name, :presence => true, :uniqueness => true
  validates :unixname, :uniqueness => true, :presence => true, :format => { :with => /^[a-zA-Z0-9_]+$/ }, :allow_nil => false, :allow_blank => false
  validates :distrib_type, :presence => true, :allow_nil => :false, :allow_blank => false, :inclusion => {:in => APP_CONFIG['distr_types']}

  after_create :make_owner_rel
  before_save :check_owner_rel
#  before_save :create_directory
#  after_destroy :remove_directory
  before_create :xml_rpc_create, :unless => lambda {Thread.current[:skip]}
  before_destroy :xml_rpc_destroy
#  before_update :check_freezing
  after_create lambda { 
    unless self.hidden? 
      #add_downloads_symlink 
      mount_directory_for_rsync
    end
  }
  
  after_destroy lambda { 
    unless self.hidden? 
      #remove_downloads_symlink
      umount_directory_for_rsync
    end
  }

  scope :by_visibilities, lambda {|v| {:conditions => ['visibility in (?)', v.join(',')]}}
  scope :open, where(:visibility => 'open')
  scope :hidden, where(:visibility => 'hidden')
  scope :main, where(:platform_type => 'main')
  scope :personal, where(:platform_type => 'personal')

  #attr_accessible :visibility

  def urpmi_list(host, pair = nil)
    blank_pair = {:login => 'login', :pass => 'password'} 
    pair = blank_pair if pair.blank?
    urpmi_commands = []
    
    pls = Platform.main.open
    pls << self
    pls.each do |pl|
      local_pair = pl.id != self.id ? blank_pair : pair
      tail = (pl.id != self.id && pl.distrib_type == APP_CONFIG['distr_types'].first) ? "/$ARCH/main/release" : ""
      head = pl.hidden? ? "http://#{ local_pair[:login] }@#{ local_pair[:pass] }:#{ host }/private/" : "http://#{ host }/downloads/"
      urpmi_commands << [
        "urpmi.addmedia #{ head }#{ pl.owner.try(:uname) }/repository/#{ pl.name }#{ tail }",
        pl.name
      ]
    end
    
    return urpmi_commands
  end

  def path
    build_path(unixname)
  end

  def hidden?
    self.visibility == 'hidden'
  end

  def personal?
    platform_type == 'personal'
  end

  def full_clone(attrs) # :name, :unixname, :owner
    clone.tap do |c|
      c.attributes = attrs
      c.updated_at = nil; c.created_at = nil # :id = nil
      c.parent = self
      new_attrs = {:platform_id => nil}
      c.repositories = repositories.map{|r| r.full_clone(new_attrs.merge(:owner_id => attrs[:owner_id], :owner_type => attrs[:owner_type]))}
      c.products = products.map{|p| p.full_clone(new_attrs)}
    end
  end

  # TODO * make it Delayed Job *  
  def make_clone(attrs)
    p = full_clone(attrs)
    begin
      Thread.current[:skip] = true
      p.save and xml_rpc_clone(attrs[:unixname])
    ensure
      Thread.current[:skip] = false
    end
    # (Thread.current[:skip] = true) and p.save and (Thread.current[:skip] = false or true) and xml_rpc_clone(attrs[:unixname])
    p
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
  
  def change_visibility
    if !self.hidden?
      self.update_attribute(:visibility, 'hidden')
      #remove_downloads_symlink
      umount_directory_for_rsync
    else
      self.update_attribute(:visibility, 'open')
      #add_downloads_symlink
      mount_directory_for_rsync
    end
  end
    
  #def add_downloads_symlink
  #  #raise "Personal platform path #{ symlink_downloads_path } already exists!" if File.exists?(symlink_downloads_path) && File.directory?(symlink_downloads_path)
  #  return true if File.exists?(symlink_downloads_path) && File.directory?(symlink_downloads_path)
  #  FileUtils.symlink path, symlink_downloads_path
  #end
  
  def mount_directory_for_rsync
    #system("touch #{ Rails.root.join('tmp') }/mount_rsync")
    FileUtils.rm_f "#{ Rails.root.join('tmp', 'umount', self.unixname) }" if File.exist? "#{ Rails.root.join('tmp', 'umount', self.unixname) }"
    FileUtils.mkdir "#{ Rails.root.join('tmp', 'mount') }" unless File.exist? "#{ Rails.root.join('tmp', 'mount') }"
    system("touch #{ Rails.root.join('tmp', 'mount', self.unixname) }")
  end
  
  #def remove_downloads_symlink
  #  #raise "Personal platform path #{ symlink_downloads_path } does not exists!" if !(File.exists?(symlink_downloads_path) && File.directory?(symlink_downloads_path))
  #  return true if !(File.exists?(symlink_downloads_path) && File.directory?(symlink_downloads_path))
  #  FileUtils.rm_rf symlink_downloads_path 
  #end
  
  def umount_directory_for_rsync
    #system("touch #{ Rails.root.join('tmp') }/unmount_rsync")
    FileUtils.rm_f "#{ Rails.root.join('tmp', 'mount', self.unixname) }" if File.exist? "#{ Rails.root.join('tmp', 'mount', self.unixname) }"
    FileUtils.mkdir "#{ Rails.root.join('tmp', 'umount') }" unless File.exist? "#{ Rails.root.join('tmp', 'umount') }"
    system("touch #{ Rails.root.join('tmp', 'umount', self.unixname) }") 
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

    def xml_rpc_create
      result = BuildServer.add_platform unixname, APP_CONFIG['root_path'] + '/platforms' , distrib_type
      if result == BuildServer::SUCCESS
        return true
      else
        raise "Failed to create platform #{name} with code #{result}. Path: #{build_path(unixname)}"
      end
    end

    def xml_rpc_destroy
      result = BuildServer.delete_platform unixname
      if result == BuildServer::SUCCESS
        return true
      else
        raise "Failed to delete platform #{unixname} with code #{result}."
      end
    end

    def xml_rpc_clone(new_unixname)
      result = BuildServer.clone_platform new_unixname, self.unixname, APP_CONFIG['root_path'] + '/platforms'
      if result == BuildServer::SUCCESS
        return true
      else
        raise "Failed to clone platform #{name} with code #{result}. Path: #{build_path(unixname)} to platform #{new_unixname}"
      end
    end

    def check_freezing
      if released_changed?
        BuildServer.freeze_platform self.unixname
      end
    end
    
    def symlink_downloads_path
      "#{ DOWNLOADS_PATH }/#{ self.unixname }"
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

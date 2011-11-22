#require 'lib/build_server.rb'
class Platform < ActiveRecord::Base
  DOWNLOADS_PATH = RAILS_ROOT + '/public/downloads'
  VISIBILITIES = ['open', 'hidden']

  belongs_to :parent, :class_name => 'Platform', :foreign_key => 'parent_platform_id'
  belongs_to :owner, :polymorphic => true

  has_many :repositories, :dependent => :destroy
  has_many :products, :dependent => :destroy

  has_many :relations, :as => :target, :dependent => :destroy
  has_many :objects, :as => :target, :class_name => 'Relation', :dependent => :destroy
  has_many :members, :through => :objects, :source => :object, :source_type => 'User'
  has_many :groups,  :through => :objects, :source => :object, :source_type => 'Group'

  validates :name, :presence => true, :uniqueness => true
  validates :unixname, :uniqueness => true, :presence => true, :format => { :with => /^[a-z0-9_]+$/ }, :allow_nil => false, :allow_blank => false
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
    urpmi_commands = ActiveSupport::OrderedHash.new

    Platform.main.open.each do |pl|
      urpmi_commands[pl.name] = []
      local_pair = pl.id != self.id ? blank_pair : pair
      head = hidden? ? "http://#{local_pair[:login]}@#{local_pair[:pass]}:#{host}/private/" : "http://#{host}/downloads/"
      if pl.distrib_type == APP_CONFIG['distr_types'].first
        Arch.all.each do |arch|
          tail = "/#{arch.name}/main/release"
          urpmi_commands[pl.name] << "urpmi.addmedia #{unixname} #{head}#{unixname}/repository/#{pl.unixname}#{tail}"
        end
      else
        tail = ''
        urpmi_commands[pl.name] << "urpmi.addmedia #{unixname} #{head}#{unixname}/repository/#{pl.unixname}#{tail}"
      end
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
    FileUtils.rm_rf "#{ Rails.root.join('tmp', 'umount', self.unixname) }" if File.exist? "#{ Rails.root.join('tmp', 'umount', unixname) }"
    FileUtils.mkdir_p "#{ Rails.root.join('tmp', 'mount', unixname) }"
    Arch.all.each do |arch|
      host = EventLog.current_controller.request.host_with_port rescue ::Rosa::Application.config.action_mailer.default_url_options[:host]
      url = "http://#{host}/downloads/#{unixname}/repository/"
      str = "country=Russian Federation,city=Moscow,latitude=52.18,longitude=48.88,bw=1GB,version=2011,arch=#{arch.name},type=distrib,url=#{url}\n"
      File.open(Rails.root.join('tmp', 'mount', unixname, "#{unixname}.#{arch.name}.list"), 'w') {|f| f.write(str) }
    end
  end

  #def remove_downloads_symlink
  #  #raise "Personal platform path #{ symlink_downloads_path } does not exists!" if !(File.exists?(symlink_downloads_path) && File.directory?(symlink_downloads_path))
  #  return true if !(File.exists?(symlink_downloads_path) && File.directory?(symlink_downloads_path))
  #  FileUtils.rm_rf symlink_downloads_path 
  #end

  def umount_directory_for_rsync
    #system("touch #{ Rails.root.join('tmp') }/unmount_rsync")
    FileUtils.rm_rf "#{ Rails.root.join('tmp', 'mount', unixname) }" if File.exist? "#{ Rails.root.join('tmp', 'mount', unixname) }"
    FileUtils.mkdir_p "#{ Rails.root.join('tmp', 'umount', unixname) }"
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
      r = relations.build :object_id => owner.id, :object_type => 'User', :role => 'admin'
      r.save
    end

    def check_owner_rel
      if !new_record? and owner_id_changed?
        relations.by_object(owner).delete_all if owner_type_was
        make_owner_rel if owner
      end
    end

end

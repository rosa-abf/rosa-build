#require 'lib/build_server.rb'
class Platform < ActiveRecord::Base
  VISIBILITIES = ['open', 'hidden']

  belongs_to :parent, :class_name => 'Platform', :foreign_key => 'parent_platform_id'
  belongs_to :owner, :polymorphic => true

  has_many :repositories, :dependent => :destroy
  has_many :products, :dependent => :destroy

  has_many :relations, :as => :target, :dependent => :destroy
  has_many :objects, :as => :target, :class_name => 'Relation', :dependent => :destroy
  has_many :members, :through => :objects, :source => :object, :source_type => 'User'
  has_many :groups,  :through => :objects, :source => :object, :source_type => 'Group'

  validates :description, :presence => true, :uniqueness => true
  if !Rails.env.development?
    validates :name, :uniqueness => true, :presence => true, :format => { :with => /^[a-zA-Z0-9_]+$/ }
  end
  validates :distrib_type, :presence => true, :inclusion => {:in => APP_CONFIG['distr_types']}

  before_create :xml_rpc_create, :unless => lambda {Thread.current[:skip]}
  before_destroy :xml_rpc_destroy
#  before_update :check_freezing
  after_create lambda { mount_directory_for_rsync unless hidden? }
  after_destroy lambda { umount_directory_for_rsync unless hidden? }
  after_update :update_owner_relation

  scope :by_visibilities, lambda {|v| {:conditions => ['visibility in (?)', v.join(',')]}}
  scope :open, where(:visibility => 'open')
  scope :hidden, where(:visibility => 'hidden')
  scope :main, where(:platform_type => 'main')
  scope :personal, where(:platform_type => 'personal')

  #attr_accessible :visibility

  include Modules::Models::Owner

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
          urpmi_commands[pl.name] << "urpmi.addmedia #{name} #{head}#{name}/repository/#{pl.name}#{tail}"
        end
      else
        tail = ''
        urpmi_commands[pl.name] << "urpmi.addmedia #{name} #{head}#{name}/repository/#{pl.name}#{tail}"
      end
    end

    return urpmi_commands
  end

  def path
    build_path(name)
  end

  def mount_path
    Rails.root.join("public", "downloads", name)
  end

  def hidden?
    visibility == 'hidden'
  end

  def personal?
    platform_type == 'personal'
  end

  def full_clone(attrs) # :description, :name, :owner
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
      p.save and xml_rpc_clone(attrs[:name])
    ensure
      Thread.current[:skip] = false
    end
    p
  end

  def name
    released? ? "#{self[:name]} #{I18n.t("layout.platforms.released_suffix")}" : self[:name]
  end
  
  def change_visibility
    if !self.hidden?
      self.update_attribute(:visibility, 'hidden')
      umount_directory_for_rsync
    else
      self.update_attribute(:visibility, 'open')
      mount_directory_for_rsync
    end
  end

  def mount_directory_for_rsync
    # umount_directory_for_rsync # TODO ignore errors
    system("sudo mkdir -p #{mount_path}")
    system("sudo mount --bind #{path} #{mount_path}")
    Arch.all.each do |arch|
      host = EventLog.current_controller.request.host_with_port rescue ::Rosa::Application.config.action_mailer.default_url_options[:host]
      url = "http://#{host}/downloads/#{name}/repository/"
      str = "country=Russian Federation,city=Moscow,latitude=52.18,longitude=48.88,bw=1GB,version=2011,arch=#{arch.name},type=distrib,url=#{url}\n"
      File.open(File.join(mount_path, "#{name}.#{arch.name}.list"), 'w') {|f| f.write(str) }
    end
  end

  def umount_directory_for_rsync
    system("sudo umount #{mount_path}")
    system("sudo rm -Rf #{mount_path}")
  end

  protected

    def build_path(dir)
      File.join(APP_CONFIG['root_path'], 'platforms', dir)
    end

    def xml_rpc_create
      result = BuildServer.add_platform name, APP_CONFIG['root_path'] + '/platforms' , distrib_type
      if result == BuildServer::SUCCESS
        return true
      else
        raise "Failed to create platform #{name} with code #{result}. Path: #{build_path(name)}"
      end
    end

    def xml_rpc_destroy
      result = BuildServer.delete_platform name
      if result == BuildServer::SUCCESS
        return true
      else
        raise "Failed to delete platform #{name} with code #{result}."
      end
    end

    def xml_rpc_clone(new_name)
      result = BuildServer.clone_platform new_name, self.name, APP_CONFIG['root_path'] + '/platforms'
      if result == BuildServer::SUCCESS
        return true
      else
        raise "Failed to clone platform #{name} with code #{result}. Path: #{build_path(name)} to platform #{new_name}"
      end
    end

    def check_freezing
      if released_changed?
        BuildServer.freeze_platform self.name
      end
    end
end

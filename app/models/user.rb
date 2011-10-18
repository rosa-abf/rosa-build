require 'digest/md5'
class User < ActiveRecord::Base
  has_many :targets, :as => :object, :class_name => 'Relation'

  has_many :own_projects, :as => :owner, :class_name => 'Project'
  has_many :own_groups,   :foreign_key => :owner_id, :class_name => 'Group'

  has_many :groups,       :through => :targets, :source => :target, :source_type => 'Group',      :autosave => true
  has_many :projects,     :through => :targets, :source => :target, :source_type => 'Project',    :autosave => true
  has_many :platforms,    :through => :targets, :source => :target, :source_type => 'Platform',   :autosave => true
  has_many :repositories, :through => :targets, :source => :target, :source_type => 'Repository', :autosave => true


  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  attr_accessible :email, :password, :password_confirmation, :remember_me, :name, :uname

  validates :uname, :presence => true, :uniqueness => true, :format => { :with => /^[a-zA-Z0-9_]+$/ }, :allow_nil => false, :allow_blank => false

  before_validation :generate_password, :on => :create
  after_create :send_notification_email

  before_save :create_dir
  after_destroy :remove_dir

  def path
    build_path(uname)
  end

  protected

    def generate_password
      if self.password.blank?
        self.password = self.password_confirmation = Digest::MD5.hexdigest(Date.today.to_s)[0..6] 
      end
    end

    def send_notification_email
      UserMailer.new_user_notification(self).deliver
    end

    def build_path(dir)
      File.join(APP_CONFIG['root_path'], 'users', dir)
    end

    def create_dir
      exists = File.exists?(path) && File.directory?(path)
      raise "Directory #{path} already exists" if exists
      if new_record?
        FileUtils.mkdir_p(path)
      elsif uname_changed?
        FileUtils.mv(build_path(uname_was), build_path(uname))
      end 
    end

    def remove_dir
      exists = File.exists?(path) && File.directory?(path)
      raise "Directory #{path} didn't exists" unless exists
      FileUtils.rm_rf(path)
    end
end

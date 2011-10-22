class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable, :omniauthable, # :token_authenticatable, :encryptable, :timeoutable
         :recoverable, :rememberable, :validatable #, :trackable, :confirmable, :lockable

  has_many :authentications, :dependent => :destroy

  has_many :roles, :through => :targets

  has_many :targets, :as => :object, :class_name => 'Relation'

  has_many :own_projects, :as => :owner, :class_name => 'Project'
  has_many :own_groups,   :foreign_key => :owner_id, :class_name => 'Group'

  has_many :groups,       :through => :targets, :source => :target, :source_type => 'Group',      :autosave => true
  has_many :projects,     :through => :targets, :source => :target, :source_type => 'Project',    :autosave => true
  has_many :platforms,    :through => :targets, :source => :target, :source_type => 'Platform',   :autosave => true
  has_many :repositories, :through => :targets, :source => :target, :source_type => 'Repository', :autosave => true

  validates :uname, :presence => true, :uniqueness => {:case_sensitive => false}, :format => { :with => /^[a-zA-Z0-9_]+$/ }, :allow_nil => false, :allow_blank => false

  attr_accessible :email, :password, :password_confirmation, :remember_me, :login, :name, :ssh_key, :uname
  attr_readonly :uname
  attr_accessor :login

  before_save :create_dir
  after_destroy :remove_dir
  # after_create() { UserMailer.new_user_notification(self).deliver }

  class << self
    def find_for_database_authentication(warden_conditions)
      conditions = warden_conditions.dup
      login = conditions.delete(:login)
      where(conditions).where(["lower(uname) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    end

    def new_with_session(params, session)
      super.tap do |user|
        if data = session["devise.omniauth_data"]
          if info = data['user_info'] and info.present?
            user.email = info['email'].presence if user.email.blank?
            user.uname ||= info['nickname'].presence || info['username'].presence
            user.name ||= info['name'].presence || [info['first_name'], info['last_name']].join(' ').strip
          end
          user.password = Devise.friendly_token[0,20] # stub password
          user.authentications.build :uid => data['uid'], :provider => data['provider']
        end
      end
    end
  end

  def update_with_password(params={})
    params.delete(:current_password)
    # self.update_without_password(params) # Don't allow password update
    if params[:password].blank?
      params.delete(:password)
      params.delete(:password_confirmation) if params[:password_confirmation].blank?
    end
    result = update_attributes(params)
    clean_up_passwords
    result
  end

  def path
    build_path(uname)
  end

  protected
    def build_path(dir)
      puts APP_CONFIG['root_path']
      puts dir
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

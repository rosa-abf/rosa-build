class User < ActiveRecord::Base
  relationable :as => :object
  inherit_rights_from :groups

  devise :database_authenticatable, :registerable, :omniauthable, # :token_authenticatable, :encryptable, :timeoutable
         :recoverable, :rememberable, :validatable #, :trackable, :confirmable, :lockable

  has_many :authentications, :dependent => :destroy

  belongs_to :global_role, :class_name => 'Role'
  has_many :roles, :through => :targets

  has_many :targets, :as => :object, :class_name => 'Relation'

  has_many :own_projects, :as => :owner, :class_name => 'Project'
  has_many :own_groups,   :foreign_key => :owner_id, :class_name => 'Group'

  has_many :groups,       :through => :targets, :source => :target, :source_type => 'Group',      :autosave => true
  has_many :projects,     :through => :targets, :source => :target, :source_type => 'Project',    :autosave => true
  has_many :platforms,    :through => :targets, :source => :target, :source_type => 'Platform',   :autosave => true
  has_many :repositories, :through => :targets, :source => :target, :source_type => 'Repository', :autosave => true

  include PersonalRepository

  validates :uname, :presence => true, :uniqueness => {:case_sensitive => false}, :format => { :with => /^[a-zA-Z0-9_]+$/ }, :allow_nil => false, :allow_blank => false
  validates :ssh_key, :uniqueness => true
  validate { errors.add(:uname, :taken) if Group.where('uname LIKE ?', uname).present? }
  #TODO: Replace this simple cross-table uniq validation by more progressive analog
  validate lambda {
    errors.add(:uname, I18n.t('flash.user.group_uname_exists')) if Group.exists? :uname => uname
  }

  attr_accessible :email, :password, :password_confirmation, :remember_me, :login, :name, :ssh_key, :uname
  attr_readonly :uname
  attr_accessor :login

  before_update {
    if ssh_key_was.blank? and ssh_key.present?
      create_ssh_key ssh_key
    elsif ssh_key_was.present? and ssh_key.blank?
      destroy_ssh_key ssh_key_was
    elsif ssh_key_changed?
      update_ssh_key ssh_key_was, ssh_key
    end
  }
  before_destroy { destroy_ssh_key(ssh_key) }
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

  protected

    def create_ssh_key(key)
      with_ga do |ga|
        ga.store_key! key
        own_projects.each do |project|
          repo = ga.find_repo(project.git_repo_name)
          repo.add_key(key, 'RW') if repo
        end
        ga.save_and_release
      end
    end

    def update_ssh_key(old_key, new_key)
      with_ga do |ga|
        ga.replace_key! old_key, new_key
        begin
          ga.repos.replace_key old_key, new_key #, options = {}
        rescue Gitolito::GitoliteAdmin::Repo::KeyDoesntExistsError
          nil
        end
        ga.save_and_release
      end
    end

    def destroy_ssh_key(key)
      with_ga do |ga|
        ga.repos.rm_key key
        ga.rm_key! key
        ga.save_and_release
      end
    end
end

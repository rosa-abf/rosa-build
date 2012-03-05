# -*- encoding : utf-8 -*-
class User < ActiveRecord::Base
  ROLES = ['admin']
  LANGUAGES_FOR_SELECT = [['Russian', 'ru'], ['English', 'en']]
  LANGUAGES = LANGUAGES_FOR_SELECT.map(&:last)

  has_attached_file :avatar, :styles => { :micro => "16x16", :small => "30x30>", :medium => "40x40>", :big => "81x81" }

  devise :database_authenticatable, :registerable, #:omniauthable, # :token_authenticatable, :encryptable, :timeoutable
         :recoverable, :rememberable, :validatable #, :trackable, :confirmable, :lockable

  has_one :notifier, :class_name => 'Settings::Notifier' #:notifier

  has_many :activity_feeds

  has_many :authentications, :dependent => :destroy
  has_many :build_lists, :dependent => :destroy
  has_many :subscribes, :foreign_key => :user_id, :dependent => :destroy
  has_many :comments, :dependent => :destroy

  has_many :relations, :as => :object, :dependent => :destroy
  has_many :targets, :as => :object, :class_name => 'Relation'

  has_many :projects,     :through => :targets, :source => :target, :source_type => 'Project',    :autosave => true
  has_many :groups,       :through => :targets, :source => :target, :source_type => 'Group',      :autosave => true
  has_many :platforms,    :through => :targets, :source => :target, :source_type => 'Platform',   :autosave => true

  has_many :own_projects, :as => :owner, :class_name => 'Project', :dependent => :destroy
  has_many :own_groups,   :foreign_key => :owner_id, :class_name => 'Group', :dependent => :destroy
  has_many :own_platforms, :as => :owner, :class_name => 'Platform', :dependent => :destroy

  include Modules::Models::PersonalRepository

  validates :uname, :presence => true, :uniqueness => {:case_sensitive => false}, :format => { :with => /^[a-z0-9_]+$/ }
  validate { errors.add(:uname, :taken) if Group.where('uname LIKE ?', uname).present? }
  validates :role, :inclusion => {:in => ROLES}, :allow_blank => true
  validates :language, :inclusion => {:in => LANGUAGES}, :allow_blank => true
  validates_confirmation_of :password

  attr_accessor :password, :password_confirmation, :current_password
  attr_accessible :email, :password, :password_confirmation, :current_password, :remember_me, :login, :name, :ssh_key, :uname, :language,
                  :site, :company, :professional_experience, :location, :avatar
  attr_readonly :uname, :own_projects_count
  attr_readonly :uname
  attr_accessor :login

  after_create :create_settings_notifier

  def admin?
    role == 'admin'
  end

  def user?
    persisted?
  end

  def guest?
    new_record?
  end

  def fullname
    return "#{uname} (#{name})"
  end
  class << self
    def find_for_database_authentication(warden_conditions)
      conditions = warden_conditions.dup
      login = conditions.delete(:login)
      where(conditions).where(["lower(uname) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    end

    def new_with_session(params, session)
      super.tap do |user|
        if data = session["devise.omniauth_data"]
          if info = data['info'] and info.present?
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

  def commentor?(commentable)
    comments.exists?(:commentable_type => commentable.class.name, :commentable_id => commentable.id.hex)
  end

  def committer?(commit)
    email.downcase == commit.committer.email.downcase
  end

  #def avatar(size)
  #  "https://secure.gravatar.com/avatar/#{Digest::MD5.hexdigest(email.downcase)}?s=#{size}&r=pg"
  #end

  private

  def create_settings_notifier
    self.create_notifier
  end

end

# -*- encoding : utf-8 -*-
class User < ActiveRecord::Base
  ROLES = ['', 'admin', 'banned']
  LANGUAGES_FOR_SELECT = [['Russian', 'ru'], ['English', 'en']]
  LANGUAGES = LANGUAGES_FOR_SELECT.map(&:last)
  MAX_AVATAR_SIZE = 5.megabyte

  has_attached_file :avatar, :styles =>
    { :micro => { :geometry => "16x16#",  :format => :jpg, :convert_options => '-strip -background white -flatten -quality 70'},
       :small => { :geometry => "30x30#",  :format => :jpg, :convert_options => '-strip -background white -flatten -quality 70'},
       :medium => { :geometry => "40x40#",  :format => :jpg, :convert_options => '-strip -background white -flatten -quality 70'},
       :big => { :geometry => "81x81#",  :format => :jpg, :convert_options => '-strip -background white -flatten -quality 70'}
    }
  validates_inclusion_of :avatar_file_size, :in => (0..MAX_AVATAR_SIZE), :allow_nil => true

  devise :database_authenticatable, :registerable, #:omniauthable, # :token_authenticatable, :encryptable, :timeoutable
         :recoverable, :rememberable, :validatable, :lockable #, :trackable, :confirmable

  has_one :notifier, :class_name => 'Settings::Notifier', :dependent => :destroy #:notifier

  has_many :activity_feeds, :dependent => :destroy

  has_many :authentications, :dependent => :destroy
  has_many :build_lists, :dependent => :destroy
  has_many :subscribes, :foreign_key => :user_id, :dependent => :destroy
  has_many :comments, :dependent => :destroy

  has_many :relations, :as => :object, :dependent => :destroy
  has_many :targets, :as => :object, :class_name => 'Relation', :dependent => :destroy

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

  attr_accessible :email, :password, :password_confirmation, :current_password, :remember_me, :login, :name, :uname, :language,
                  :site, :company, :professional_experience, :location, :avatar
  attr_readonly :uname, :own_projects_count
  attr_accessor :login

  scope :search_order, order("CHAR_LENGTH(uname) ASC")
  scope :search, lambda {|q| where("uname ILIKE ?", "%#{q}%")}
  scope :banned, where(:role => 'banned')
  scope :admin, where(:role => 'admin')
  scope :real, where(:role => ['', nil])

  after_create lambda { self.create_notifier }

  def admin?
    role == 'admin'
  end

  def user?
    persisted?
  end

  def guest?
    new_record?
  end

  def access_locked?
      role == 'banned'
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

  # def update_with_password(params={})
  #   params.delete(:current_password)
  #   # self.update_without_password(params) # Don't allow password update
  #   if params[:password].blank?
  #     params.delete(:password)
  #     params.delete(:password_confirmation) if params[:password_confirmation].blank?
  #   end
  #   result = update_attributes(params)
  #   clean_up_passwords
  #   result
  # end

  def commentor?(commentable)
    comments.exists?(:commentable_type => commentable.class.name, :commentable_id => commentable.id.hex)
  end

  def committer?(commit)
    email.downcase == commit.committer.email.downcase
  end

  def owner_of? object
    if object.respond_to? :owner
      object.owner_id == self.id or self.group_ids.include? object.owner_id
    else
      false
    end
  end

  def user_appeal
    name.blank? ? uname : name
  end

  private

  def create_settings_notifier
    self.create_notifier
  end
end

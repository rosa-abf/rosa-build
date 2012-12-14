# -*- encoding : utf-8 -*-
class User < Avatar
  ROLES = ['', 'admin', 'banned', 'tester']
  LANGUAGES_FOR_SELECT = [['Russian', 'ru'], ['English', 'en']]
  LANGUAGES = LANGUAGES_FOR_SELECT.map(&:last)

  devise :database_authenticatable, :registerable, :omniauthable, :token_authenticatable,# :encryptable, :timeoutable
         :recoverable, :rememberable, :validatable, :lockable, :confirmable#, :reconfirmable, :trackable

  has_one :notifier, :class_name => 'SettingsNotifier', :dependent => :destroy #:notifier

  has_many :activity_feeds, :dependent => :destroy

  has_many :authentications, :dependent => :destroy
  has_many :build_lists, :dependent => :destroy
  has_many :subscribes, :foreign_key => :user_id, :dependent => :destroy
  has_many :comments, :dependent => :destroy

  has_many :relations, :as => :actor, :dependent => :destroy
  has_many :targets, :as => :actor, :class_name => 'Relation', :dependent => :destroy

  has_many :projects,     :through => :targets, :source => :target, :source_type => 'Project',    :autosave => true
  has_many :groups,       :through => :targets, :source => :target, :source_type => 'Group',      :autosave => true
  has_many :platforms,    :through => :targets, :source => :target, :source_type => 'Platform',   :autosave => true

  has_many :own_projects, :as => :owner, :class_name => 'Project', :dependent => :destroy
  has_many :own_groups,   :foreign_key => :owner_id, :class_name => 'Group', :dependent => :destroy
  has_many :own_platforms, :as => :owner, :class_name => 'Platform', :dependent => :destroy

  has_many :key_pairs

  validates :uname, :presence => true, :uniqueness => {:case_sensitive => false}, :format => {:with => /\A[a-z0-9_]+\z/}, :reserved_name => true
  validate { errors.add(:uname, :taken) if Group.by_uname(uname).present? }
  validates :role, :inclusion => {:in => ROLES}, :allow_blank => true
  validates :language, :inclusion => {:in => LANGUAGES}, :allow_blank => true

  attr_accessible :email, :password, :password_confirmation, :current_password, :remember_me, :login, :name, :uname, :language,
                  :site, :company, :professional_experience, :location
  attr_readonly :uname
  attr_accessor :login

  scope :opened, where('1=1')
  scope :banned, where(:role => 'banned')
  scope :admin, where(:role => 'admin')
  scope :tester, where(:role => 'tester')
  scope :real, where(:role => ['', nil])

  scope :member_of_project, lambda {|item|
    where "#{table_name}.id IN (?)", item.members.map(&:id).uniq
  }

  after_create lambda { self.create_notifier }
  before_create :ensure_authentication_token

  include Modules::Models::PersonalRepository
  include Modules::Models::ActsLikeMember

  def admin?
    role == 'admin'
  end

  def user?
    persisted?
  end

  def guest?
    new_record?
  end

  def tester?
    role == 'tester'
  end

  def access_locked?
    role == 'banned'
  end

  def fullname
    return name.present? && name.length > 0 ? "#{uname} (#{name})" : uname
  end

  def user_appeal
    name.presence || uname
  end

  class << self
    def find_for_database_authentication(warden_conditions)
      conditions = warden_conditions.dup

      login = conditions.delete(:login)
      pass  = conditions.delete(:pass)
      user = User.where(conditions).where(:authentication_token => login).first ||
             User.where(conditions).where(["lower(uname) = :value OR lower(email) = :value", { :value => login.downcase}]).first
      return user if !user.access_locked? and (user.authentication_token == login or user.valid_password?(pass))
      nil
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

  def best_role target
    roles = target_roles(target)
    return nil if roles.count == 0
    %w(admin writer reader).each {|role| return role if roles.include?(role)}
    raise "unknown user #{self.uname} roles #{roles}"
  end

  protected

  def target_roles target
    rel, gr, roles = target.relations, self.groups, []

    if target.owner.class == Group
      owner_group = self.groups.where(:id => target.owner.id).first
      roles += owner_group.actors.where(:actor_id => self) if owner_group# user group is owner

      gr = gr.where('groups.id != ?', target.owner.id) # exclude target owner group from users group list
    end
    roles += rel.where(:actor_id => self.id, :actor_type => 'User') # user is member
    roles += rel.where(:actor_id => gr, :actor_type => 'Group') # user group is member
    roles.map(&:role).uniq
  end

end

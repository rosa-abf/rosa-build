class User < Avatar
  extend FriendlyId
  friendly_id :uname, use: [:finders]

  include PersonalRepository
  include ActsLikeMember
  include Feed::User
  include EventLoggable
  include TokenAuthenticatable

  ROLES = ['', 'admin', 'banned', 'tester']
  EXTENDED_ROLES = ROLES | ['system']
  LANGUAGES_FOR_SELECT = [['Russian', 'ru'], ['English', 'en']]
  LANGUAGES = LANGUAGES_FOR_SELECT.map(&:last)
  NAME_REGEXP = /[a-z0-9_]+/

  devise :database_authenticatable, :registerable, :omniauthable,
         :recoverable, :rememberable, :validatable, :lockable, :confirmable
  devise :omniauthable, omniauth_providers: [:facebook, :google_oauth2, :github]

  has_one :notifier,       class_name: 'SettingsNotifier',  dependent: :destroy #:notifier
  has_one :builds_setting, class_name: 'UserBuildsSetting', dependent: :destroy

  has_many :activity_feeds, dependent: :destroy

  has_many :authentications, dependent: :destroy
  has_many :build_lists, dependent: :destroy
  has_many :subscribes, foreign_key: :user_id, dependent: :destroy
  has_many :comments, dependent: :destroy

  has_many :relations, as: :actor, dependent: :destroy
  has_many :targets, as: :actor, class_name: 'Relation', dependent: :destroy

  has_many :projects,     through: :targets, source: :target, source_type: 'Project',    autosave: true
  has_many :groups,       through: :targets, source: :target, source_type: 'Group',      autosave: true
  has_many :platforms,    through: :targets, source: :target, source_type: 'Platform',   autosave: true
  has_many :repositories, through: :targets, source: :target, source_type: 'Repository'

  has_many :own_projects, as: :owner, class_name: 'Project', dependent: :destroy
  has_many :own_groups,   foreign_key: :owner_id, class_name: 'Group', dependent: :destroy
  has_many :own_platforms, as: :owner, class_name: 'Platform', dependent: :destroy
  has_many :issues
  has_many :assigned_issues, foreign_key: :assignee_id, class_name: 'Issue', dependent: :nullify

  has_many :key_pairs
  has_many :ssh_keys, dependent: :destroy

  validates :uname, presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: /\A#{NAME_REGEXP.source}\z/ },
            reserved_name: true,
            length: { maximum: 30 }
  validates :name, length: { maximum: 100 }

  validate { errors.add(:uname, :taken) if Group.by_uname(uname).present? }
  validates :role, inclusion: { in: EXTENDED_ROLES }, allow_blank: true
  validates :language, inclusion: { in: LANGUAGES }, allow_blank: true

  # attr_accessible :email, :password, :password_confirmation, :current_password, :remember_me, :login, :name, :uname, :language,
  #                 :site, :company, :professional_experience, :location, :sound_notifications, :hide_email, :delete_avatar
  attr_readonly :uname
  attr_accessor :login, :delete_avatar

  scope :opened, -> { where('users.role != \'system\' OR users.role IS NULL') }
  scope :real,   -> { where(role: ['', nil]) }
  EXTENDED_ROLES.select { |type| type.present?}.each do |type|
    scope type.to_sym, -> { where(role: type) }
  end

  scope :member_of_project, ->(item) {
    where 'users.id IN (?)', item.members.map(&:id).uniq
  }

  after_create -> { self.create_notifier unless self.system? }
  before_create :ensure_authentication_token

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

  def system?
    role == 'system'
  end

  def access_locked?
    role == 'banned'
  end

  def fullname
    return name.present? ? "#{uname} (#{name})" : uname
  end

  def user_appeal
    name.presence || uname
  end

  class << self
    def find_for_database_authentication(warden_conditions)
      conditions = warden_conditions.dup
      login = conditions.delete(:login)
      where(conditions)
      .where(["lower(uname) = :value OR lower(email) = :value OR authentication_token = :orig_value",
             { value: login.downcase, orig_value: login }]).first
    end

    def auth_by_token_or_login_pass(user, pass)
      u = User.find_for_database_authentication(login: user)
      u if u && !u.access_locked? && (u.authentication_token == user || u.valid_password?(pass))
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
    comments.exists?(commentable_type: commentable.class.name, commentable_id: commentable.id.hex)
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
    return nil if target.nil?
    roles = target_roles(target)
    return nil if roles.count == 0
    %w(admin writer reader).each {|role| return role if roles.include?(role)}
    raise "unknown user #{self.uname} roles #{roles}"
  end

  def check_assigned_issues target
    if target.is_a? Project
      assigned_issues.where(project_id: target.id).update_all(assignee_id: nil)
    else
      project_ids = ProjectPolicy::Scope.new(self, Project).membered.uniq.pluck(:id)

      issues = assigned_issues
      issues = issues.where('project_id not in (?)', project_ids) if project_ids.present?
      issues.update_all(assignee_id: nil)
    end
  end

  protected

  def target_roles target
    rel, gr, roles = target.relations, self.groups, []

    if target.owner.class == Group
      owner_group = self.groups.where(id: target.owner.id).first
      roles += owner_group.actors.where(actor_id: self) if owner_group# user group is owner

      gr = gr.where('groups.id != ?', target.owner.id) # exclude target owner group from users group list
    end

    if target.class == Group
      roles += target.actors.where(actor_id: self.id, actor_type: 'User') # user is member of a target group
    else
      roles += rel.where(actor_id: gr.pluck('DISTINCT groups.id'), actor_type: 'Group') # user group is member
    end
    roles += rel.where(actor_id: self.id, actor_type: 'User') # user is member
    roles.map(&:role).uniq
  end

end

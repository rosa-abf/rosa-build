class Group < Avatar
  include ActsLikeMember
  include PersonalRepository
  include DefaultBranchable

  belongs_to :owner, class_name: 'User'

  has_many :relations, as: :actor, dependent: :destroy
  has_many :actors, as: :target, class_name: 'Relation', dependent: :destroy
  has_many :targets, as: :actor, class_name: 'Relation', dependent: :destroy

  has_many :members,  through: :actors,  source: :actor,  source_type: 'User',    autosave: true
  has_many :projects, through: :targets, source: :target, source_type: 'Project', autosave: true

  has_many :own_projects, as: :owner, class_name: 'Project', dependent: :destroy
  has_many :own_platforms, as: :owner, class_name: 'Platform', dependent: :destroy

  validates :owner, presence: true
  validates :uname, presence: true,
            uniqueness: {case_sensitive: false},
            format: {with: /\A[a-z0-9_]+\z/},
            reserved_name: true,
            length: { maximum: 100 }
  validate { errors.add(:uname, :taken) if User.by_uname(uname).present? }

  scope :opened, -> { all }
  scope :by_owner, ->(owner) { where(owner_id: owner.id) }
  scope :by_admin, ->(admin) {
    joins(:actors).where('relations.role' => 'admin', 'relations.actor_id' => admin.id, 'relations.actor_type' => 'User')
  }
  scope :by_admin_and_writer, ->(actor) {
    joins(:actors).where('relations.role' => ['admin', 'writer'], 'relations.actor_id' => actor.id, 'relations.actor_type' => 'User')
  }

  # attr_accessible :uname, :description, :delete_avatar
  attr_readonly :uname

  attr_accessor :delete_avatar

  delegate :email, :user_appeal, to: :owner

  after_create :add_owner_to_members

  def self.can_own_project(user)
    (by_owner(user) | by_admin_and_writer(user))
  end

  def name
    uname
  end

  def add_member(member, role = 'admin')
    Relation.add_member(member, self, role, :actors)
  end

  def remove_member(member)
    Relation.remove_member(member, self)
  end

  def system?
    false
  end

  def fullname
    return description.present? ? "#{uname} (#{description})" : uname
  end

  protected

  def add_owner_to_members
    Relation.create_with_role(self.owner, self, 'admin') # members << self.owner if !members.exists?(id: self.owner.id)
  end
end

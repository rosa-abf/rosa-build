class Relation < ActiveRecord::Base
  ROLES = %w[reader writer admin]

  belongs_to :target, polymorphic: true
  belongs_to :actor, polymorphic: true, touch: true

  validates :role, inclusion: { in: ROLES }

  validates :target,
    presence: true

  validates :actor,
    presence: true

#  validate { errors.add(:actor, :taken) if Relation.where(actor_type: self.actor_type, actor_id: self.actor_id).present? }
  before_validation :add_default_role

  scope :by_user_through_groups, ->(u) {
    where("actor_type = 'User' AND actor_id = ? OR actor_type = 'Group' AND actor_id IN (?)", u.id, u.group_ids)
  }
  scope :by_actor,  ->(obj)  { where(actor_id: obj.id, actor_type: obj.class.to_s) }
  scope :by_target, ->(tar)  { where(target_id: tar.id, target_type: tar.class.to_s) }
  scope :by_role,   ->(role) { where(role: role) }

  def self.create_with_role(actor, target, role)
    r = self.new
    r.actor = actor
    r.target = target
    r.role = role
    r.save
  end

  def self.add_member(member, target, role, relation = :relations)
    if target.send(relation).exists?(actor_id: member.id, actor_type: member.class.to_s) || (target.respond_to?(:owner) && target.owner == member)
      true
    else
      rel = target.send(relation).build(role: role)
      rel.actor = member
      rel.save
    end
  end

  def self.remove_member(member, target)
    return false if target.respond_to?(:owner) && target.owner == member
    res = Relation.by_actor(member).by_target(target).each{|r| r.destroy}
    if member.is_a?(User) && ['Project', 'Group'].include?(target.class.name)
      member.check_assigned_issues target
    end
    res
  end

  protected

  def add_default_role
    self.role = ROLES.first if role.nil? || role.empty?
  end
end

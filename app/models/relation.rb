# -*- encoding : utf-8 -*-
class Relation < ActiveRecord::Base
  belongs_to :target, :polymorphic => true
  belongs_to :actor, :polymorphic => true

  ROLES = %w[reader writer admin]
  validates :role, :inclusion => {:in => ROLES}

#  validate { errors.add(:actor, :taken) if Relation.where(:actor_type => self.actor_type, :actor_id => self.actor_id).present? }
  before_validation :add_default_role

  scope :by_user_through_groups, lambda {|u| where("actor_type = 'User' AND actor_id = ? OR actor_type = 'Group' AND actor_id IN (?)", u.id, u.group_ids)}
  scope :by_actor, lambda {|obj| {:conditions => ['actor_id = ? AND actor_type = ?', obj.id, obj.class.to_s]}}
  scope :by_target, lambda {|tar| {:conditions => ['target_id = ? AND target_type = ?', tar.id, tar.class.to_s]}}
  scope :by_role, lambda {|role| {:conditions => ['role = ?', role]}}

  def self.create_with_role(actor, target, role)
    r = self.new
    r.actor = actor
    r.target = target
    r.role = role
    r.save
  end

  protected

  def add_default_role
    self.role = ROLES.first if role.nil? || role.empty?
  end
end

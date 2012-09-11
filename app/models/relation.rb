# -*- encoding : utf-8 -*-
class Relation < ActiveRecord::Base
  belongs_to :target, :polymorphic => true
  belongs_to :actor, :polymorphic => true

  ROLES = %w[reader writer admin]
  validates :role, :inclusion => {:in => ROLES}

#  validate { errors.add(:actor, :taken) if Relation.where(:actor_type => self.actor_type, :actor_id => self.actor_id).present? }
  before_validation :add_default_role

  scope :by_user_through_groups, lambda {|u| where("actor_type = 'User' AND actor_id = ? OR actor_type = 'Group' AND actor_id IN (?)", u.id, u.group_ids)}
  scope :by_actor, lambda {|obj| where(:actor_id => obj.id, :actor_type => obj.class.to_s)}
  scope :by_target, lambda {|tar| where(:target_id => tar.id, :target_type => tar.class.to_s)}
  scope :by_role, lambda {|role| where(:role => role)}

  def self.create_with_role(actor, target, role)
    r = self.new
    r.actor = actor
    r.target = target
    r.role = role
    r.save
  end

  def self.remove_member(member_id, target)
    user = User.find(member_id)
    Relation.by_actor(user).by_target(target).each{|r| r.destroy}
  end

  # @param user_remove looks like {"9"=>["1"], "32"=>["1"]}
  def self.remove_members(user_remove, target)
    user_ids = user_remove ? user_remove.map{ |k, v| k if v.first == '1' }.compact : []
    Relation.by_target(target).where(:actor_id => user_ids, :actor_type => 'User').
      each{|r| r.destroy}
  end

  protected

  def add_default_role
    self.role = ROLES.first if role.nil? || role.empty?
  end
end

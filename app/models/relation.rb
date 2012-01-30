# -*- encoding : utf-8 -*-
class Relation < ActiveRecord::Base
  belongs_to :target, :polymorphic => true
  belongs_to :object, :polymorphic => true

  ROLES = %w[reader writer admin]
  validates :role, :inclusion => {:in => ROLES}

#  validate { errors.add(:object, :taken) if Relation.where(:object_type => self.object_type, :object_id => self.object_id).present? }
  before_validation :add_default_role

  scope :by_object, lambda {|obj| {:conditions => ['object_id = ? AND object_type = ?', obj.id, obj.class.to_s]}}
  scope :by_target, lambda {|tar| {:conditions => ['target_id = ? AND target_type = ?', tar.id, tar.class.to_s]}}
  scope :by_role, lambda {|role| {:conditions => ['role = ?', role]}}

  def self.create_with_role(object, target, role)
    r = new
    r.object = object
    r.target = target
    r.role = role
    r.save
  end

  protected
    def add_default_role
      self.role = ROLES.first if role.nil? || role.empty?
    end
end

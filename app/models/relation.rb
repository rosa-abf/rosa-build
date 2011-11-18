class Relation < ActiveRecord::Base
  belongs_to :target, :polymorphic => true
  belongs_to :object, :polymorphic => true

  #has_many :role_lines
  #has_many :roles, :autosave => true, :through => :role_lines

  ROLES = %w[read write admin]
  validates :role, :inclusion => {:in => ROLES}
  
  #bitmask :roles, :as => [:read, :update] 

  scope :by_object, lambda {|obj| {:conditions => ['object_id = ? AND object_type = ?', obj.id, obj.class.to_s]}}
  scope :by_target, lambda {|tar| {:conditions => ['target_id = ? AND target_type = ?', tar.id, tar.class.to_s]}}
end

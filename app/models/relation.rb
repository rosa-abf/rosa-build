class Relation < ActiveRecord::Base
  belongs_to :target, :polymorphic => true
  belongs_to :object, :polymorphic => true
  has_many :roles, :autosave => true, :through => :role_lines
end

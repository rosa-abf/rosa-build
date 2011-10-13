class Relation < ActiveRecord::Base
  belongs_to :target, :polymorphic => true
  belongs_to :object, :polymorphic => true
  belongs_to :role
end

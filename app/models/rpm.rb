class Rpm < ActiveRecord::Base
  validate :name, :presence => true
  validate :arch_id, :presence => true
  validate :project_id, :presence => true

  belongs_to :arch
  belongs_to :project
end

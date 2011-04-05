class Rpm < ActiveRecord::Base
  validates :name, :presence => true
  validates :arch_id, :presence => true
  validates :project_id, :presence => true

  belongs_to :arch
  belongs_to :project
end

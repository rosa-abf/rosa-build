class Rpm < ActiveRecord::Base
  belongs_to :arch
  belongs_to :project

  validates :name, :arch_id, :project_id, :presence => true
end

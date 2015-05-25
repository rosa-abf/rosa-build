class ProjectStatistic < ActiveRecord::Base

  belongs_to :arch
  belongs_to :project

  validates :arch, :project, :average_build_time, :build_count, presence: true
  validates :project_id, uniqueness: { scope: :arch_id }
end

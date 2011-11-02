class AutoBuildList < ActiveRecord::Base
  belongs_to :project
  belongs_to :arch
  belongs_to :pl, :class_name => 'Platform'
  belongs_to :bpl, :class_name => 'Platform'

  def event_log_message
    {:project => project.unixname}.inspect
  end
end

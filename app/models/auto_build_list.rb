class AutoBuildList < ActiveRecord::Base
  belongs_to :project
  belongs_to :arch
  belongs_to :pl, :class_name => 'Platform'
  belongs_to :bpl, :class_name => 'Platform'
end

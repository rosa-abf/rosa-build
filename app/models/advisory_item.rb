class AdvisoryItem < ActiveRecord::Base
  belongs_to :advisory
  belongs_to :platform
  belongs_to :project
end

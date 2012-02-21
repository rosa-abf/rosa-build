class Labeling < ActiveRecord::Base
  belongs_to :issue
  belongs_to :project
  belongs_to :label

  #before_create {|t| t.project_id = t.issue.project_id}
end

class Labeling < ActiveRecord::Base
  belongs_to :issue
  belongs_to :label

  # attr_accessible :id, :label_id
end

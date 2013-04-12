class Hook < ActiveRecord::Base
  TYPES = [1, 2]

  belongs_to :project

  validates :project_id, :presence => true
  validates :data, :presence => true
  validates :type, :presence => true, :inclusion => {:in => TYPES}
  validates :type, :uniqueness => {:scope => :project_id}

  attr_accessible :data, :type

  serialize :data,  Hash
end

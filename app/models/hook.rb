class Hook < ActiveRecord::Base
  NAMES = %w[
    web
    hipchat
  ].freeze

  belongs_to :project

  validates :project_id, :presence => true
  validates :data, :presence => true
  validates :name, :presence => true, :inclusion => {:in => NAMES}

  attr_accessible :data, :name

  serialize :data,  Hash

  scope :for_name, lambda {|name| where(:name => name) if name.present? }

end

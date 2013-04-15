class Hook < ActiveRecord::Base
  include Modules::Models::WebHooks
  belongs_to :project

  before_validation :cleanup_data
  validates :project_id, :data, :presence => true
  validates :name, :presence => true, :inclusion => {:in => NAMES}

  attr_accessible :data, :name

  serialize :data,  Hash

  scope :for_name, lambda {|name| where(:name => name) if name.present? }

  protected

  def cleanup_data
    if self.name.present? && fields = SCHEMA[self.name.to_sym]
      new_data = {}
      fields.each{ |type, field| new_data[field] = self.data[field] }
      self.data = new_data
    end
  end

end

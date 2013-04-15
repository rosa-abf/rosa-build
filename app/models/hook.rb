class Hook < ActiveRecord::Base
  NAMES = %w[
    web
    hipchat
  ].freeze

  FIELDS = {
    :web      => {:url => :string},
    :hipchat  => {
      :auth_token => :string,
      :room => :string,
      :restrict_to_branch => :string,
      :notify => :boolean
    }
  }

  belongs_to :project

  before_validation :cleanup_data
  validates :project_id, :presence => true
  validates :data, :presence => true
  validates :name, :presence => true, :inclusion => {:in => NAMES}

  attr_accessible :data, :name

  serialize :data,  Hash

  scope :for_name, lambda {|name| where(:name => name) if name.present? }

  protected

  def cleanup_data
    if self.name.present? && fields = FIELDS[self.name.to_sym]
      new_data = {}
      fields.each{ |f, t| new_data[f] = self.data[f] }
      self.data = new_data
    end
  end

end

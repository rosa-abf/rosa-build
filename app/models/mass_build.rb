class MassBuild < ActiveRecord::Base
  belongs_to :platform

  before_save :set_name

  scope :by_platform, lambda { |platform| where(:platform_id => platform.id) }

  def build_all(opts={})
    platform.build_all opts.merge({:mass_build_id => self.id})
  end

  protected

  def set_name
    self.name = "#{Date.today.to_s}-#{platform.name}"
  end
end

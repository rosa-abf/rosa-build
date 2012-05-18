class MassBuild < ActiveRecord::Base
  belongs_to :platform

  before_save :set_name

  def build_all(opts={})
    platform.build_all opts.merge({:mass_build_id => self.id})
  end

  protected

  def set_name
    self.name = "#{created_at.to_date.to_s}-#{platform.name}"
  end
end

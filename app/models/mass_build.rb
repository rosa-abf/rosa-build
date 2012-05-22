class MassBuild < ActiveRecord::Base
  belongs_to :platform
  has_many :build_lists

  scope :by_platform, lambda { |platform| where(:platform_id => platform.id) }

  def build_all(opts={})
    set_name opts[:repositories]
    platform.build_all opts.merge({:mass_build_id => self.id})
  end

  private

  def set_name(repositories_ids)
    rep_names = Repository.where(:id => repositories_ids).map(&:name).join(", ")
    self.name = "#{Date.today.strftime("%d.%b")}-#{platform.name}(#{rep_names})"
    self.save!
  end
end

class MassBuild < ActiveRecord::Base
  belongs_to :platform
  belongs_to :user
  has_many :build_lists, :dependent => :destroy

  scope :by_platform, lambda { |platform| where(:platform_id => platform.id) }

  def build_all(opts={})
    auto_publish = opts[:auto_publish] || false
    set_data opts[:repositories], opts[:arches], auto_publish

    platform.build_all opts.merge({:mass_build_id => self.id})
  end

  private

  def set_data(repositories_ids, arches, auto_publish=false)
    rep_names = Repository.where(:id => repositories_ids).map(&:name).join(", ")
    self.name = "#{Date.today.strftime("%d.%b")}-#{platform.name}(#{rep_names})"
    self.arch_names = Arch.where(:id => arches).map(&:name).join(", ")
    self.auto_publish = auto_publish
    self.save
  end
end

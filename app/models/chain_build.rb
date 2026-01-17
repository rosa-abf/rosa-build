class ChainBuild < ActiveRecord::Base
  belongs_to :user
  belongs_to :platform
  has_many :build_lists

  scope :for_user, ->(user) { where(user: user) }
  scope :advancable, ->() {
    ids = BuildList.where.not(chain_build_id: nil).for_status(BuildList::WAITING_FOR_RESPONSE).select(:chain_build_id)
    where(id: ids)
  }

  def chain_container_path(downloads = true)
    if downloads
      "#{APP_CONFIG['downloads_url']}/#{platform.name}/container/chain_build_#{id}"
    else
      "#{platform.path}/container/chain_build_#{id}"
    end
  end

  def current_level
    return 0 unless build_lists.exists?

    arches_count = arches.count
    arches_by_level = Hash.new { |h, k| h[k] = [] }
    build_lists.group(:level, :arch_id).pluck('level, arch_id').sort_by(&:first).each do |x|
      arches_by_level[x[0]] << x[1]
    end
    arches_by_level.keys.map { |x| [x, arches_by_level[x].count] }.reject { |x| x[1] != arches_count }.map(&:first).max
  end

  def arches
    Arch.where(id: build_lists.where(first_in_chain: true).pluck(:arch_id))
  end

  def level_arch(level, arch_id)
    build_lists.where(level: level, arch_id: arch_id)
  end
end

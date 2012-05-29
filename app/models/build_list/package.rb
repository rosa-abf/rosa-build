class BuildList::Package < ActiveRecord::Base
  PACKAGE_TYPES = %w(source binary)

  belongs_to :build_list
  belongs_to :project
  belongs_to :platform

  attr_accessible :fullname, :name, :release, :version

  validates :build_list_id, :project_id, :platform_id, :fullname, :package_type, :name, :release, :version, :presence => true
  validates :package_type, :inclusion => PACKAGE_TYPES

  # This selects only the latest record for each (platform, project) pair (by 'latest' we mean it, i.e. the greatest created_at).
  # We select the latest created_at-s, and join the table with itself.
  scope :maintainers, joins('join(
                             select name as j_pn, package_type as j_pt, platform_id as j_plid, max(created_at) as j_ca
                             from build_list_packages
                             group by j_pn, j_pt, j_plid
                            ) lastmaints
                            on j_pn = name and j_pt = package_type and j_plid = platform_id and j_ca = created_at'
                           ).where('created_at = j_ca')

  def assignee
    project.owner.assignee
  end
end

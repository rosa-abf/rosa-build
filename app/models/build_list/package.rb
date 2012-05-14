class BuildList::Package < ActiveRecord::Base
  PACKAGE_TYPES = %w(source binary)

  belongs_to :build_list
  belongs_to :project
  belongs_to :platform

  attr_accessible :fullname, :name, :release, :version

  validates :build_list_id, :project_id, :platform_id, :fullname, :package_type, :name, :release, :version, :presence => true
  validates :package_type, :inclusion => PACKAGE_TYPES
end

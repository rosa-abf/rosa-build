class BuildList::Package < ActiveRecord::Base
  PACKAGE_TYPES = %w(source binary)

  belongs_to :build_list
  belongs_to :project
  belongs_to :platform

  attr_accessible :fullname, :name, :release, :version, :sha1

  validates :build_list_id, :project_id, :platform_id, :fullname,
            :package_type, :name, :release, :version,
            :presence => true
  validates :package_type, :inclusion => PACKAGE_TYPES
  validates :sha1, :presence => true, :if => Proc.new { |p| p.build_list.new_core? }

  default_scope order('lower(name) ASC, length(name) ASC')

  # Fetches only actual (last publised) packages.
  scope :actual,          where(:actual => true)
  scope :by_platform,     lambda {|platform| where(:platform_id => platform) }
  scope :by_name,         lambda {|name| where(:name => name) }
  scope :by_package_type, lambda {|type| where(:package_type => type) }
  scope :like_name,       lambda {|name| where('name ILIKE ?', "%#{name}%") if name.present?}

  def assignee
    project.maintainer
  end
end

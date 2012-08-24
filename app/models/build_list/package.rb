class BuildList::Package < ActiveRecord::Base
  PACKAGE_TYPES = %w(source binary)

  belongs_to :build_list
  belongs_to :project
  belongs_to :platform

  attr_accessible :fullname, :name, :release, :version

  validates :build_list_id, :project_id, :platform_id, :fullname,
            :package_type, :name, :release, :version,
            :presence => true
  validates :package_type, :inclusion => PACKAGE_TYPES

  # Fetches only actual (last publised) packages.
  scope :actual,          where(:actual => true)
  scope :by_platform,     lambda {|platform| where(:platform_id => platform) }
  scope :by_name,         lambda {|name| where(:name => name) }
  scope :by_package_type, lambda {|type| where(:package_type => type) }

  def assignee
    project.maintainer
  end

  def actualize
    ActiveRecord::Base.transaction do
      old_pkg = self.class.by_platform(self.platform_id).actual
                          .by_name(self.name).by_package_type(self.package_type)

      old_pkg.update_all(:actual => false) if old_pkg
      self.actual = true
      self.save
    end
  end
end

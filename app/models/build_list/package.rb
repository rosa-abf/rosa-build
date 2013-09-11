class BuildList::Package < ActiveRecord::Base
  PACKAGE_TYPES = %w(source binary)

  belongs_to :build_list
  belongs_to :project
  belongs_to :platform

  attr_accessor :epoch
  attr_accessible :fullname, :name, :release, :version, :sha1

  validates :build_list_id, :project_id, :platform_id, :fullname,
            :package_type, :name, :release, :version,
            :presence => true
  validates :package_type, :inclusion => PACKAGE_TYPES
  validates :sha1, :presence => true, :if => Proc.new { |p| p.build_list.new_core? }

  default_scope order("lower(#{table_name}.name) ASC, length(#{table_name}.name) ASC")

  # Fetches only actual (last publised) packages.
  scope :actual,          where(:actual => true)
  scope :by_platform,     lambda {|platform| where(:platform_id => platform) }
  scope :by_name,         lambda {|name| where(:name => name) }
  scope :by_package_type, lambda {|type| where(:package_type => type) }
  scope :like_name,       lambda {|name| where("#{table_name}.name ILIKE ?", "%#{name}%") if name.present?}

  def assignee
    project.maintainer
  end


  # Comparison between versions
  # @param [BuildList::Package] other
  # @return [Number] -1 if +other+ is greater than, 0 if +other+ is equal to,
  #   and +1 if other is less than version.
  def rpmvercmp(other)
    RPM::C.rpmvercmp to_vre_epoch_zero, other.to_vre_epoch_zero
  end

  protected

  # String representation in the form "e:v-r"
  # @return [String]
  # @note The epoch is included always. As 0 if not present
  def to_vre_epoch_zero
    evr = epoch.present? ? "#{epoch.to_i}:#{version}" : "0:#{version}"
    evr << "-#{release}" if release.present?
    evr
  end

end

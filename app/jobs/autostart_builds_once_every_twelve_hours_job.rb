class AutostartBuildsOnceEveryTwelveHoursJob < BaseActiveRecordJob
  def self.perform
    Product.autostart_iso_builds_once_a_12_hours
    Project.autostart_build_lists_once_a_12_hours
  end
end

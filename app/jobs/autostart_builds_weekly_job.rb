class AutostartBuildsWeeklyJob
  def self.perform
    Product.autostart_iso_builds_once_a_week
    Project.autostart_build_lists_once_a_week
  end
end

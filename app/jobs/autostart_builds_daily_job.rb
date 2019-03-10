class AutostartBuildsDailyJob
  def self.perform
    Product.autostart_iso_builds_once_a_day
    Project.autostart_build_lists_once_a_day
  end
end

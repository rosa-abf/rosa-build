class AutostartRegensDailyJob
  def self.perform
    Platform.autostart_metadata_regeneration("day")
  end
end

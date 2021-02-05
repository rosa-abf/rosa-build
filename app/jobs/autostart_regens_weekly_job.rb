class AutostartRegensWeeklyJob
  def self.perform
    Platform.autostart_metadata_regeneration("week")
  end
end

class BuildListObserver < ActiveRecord::Observer
  observe :build_list

  def before_update(record)
    if record.status_changed?
      record.started_at = Time.now if record.status == BuildServer::BUILD_STARTED
      if [BuildServer::BUILD_ERROR, BuildServer::SUCCESS].include? record.status
        # stores time interval beetwin build start and finish in seconds
        record.duration = record.current_duration
      end
    end
  end
end

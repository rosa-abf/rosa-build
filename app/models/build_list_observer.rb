class BuildListObserver < ActiveRecord::Observer
  observe :build_list

  def before_update(record)
    if record.status_changed?
      record.started_at = Time.now if record.status == BuildServer::BUILD_STARTED
      if [BuildServer::BUILD_ERROR, BuildServer::SUCCESS].include? record.status
        # stores time interval beetwin build start and finish in seconds
        record.duration = record.current_duration

        if record.status == BuildServer::SUCCESS
          # Update project average build time
          build_count = record.project.build_count
          new_av_time = ( record.project.average_build_time * build_count + record.duration ) / ( build_count + 1 )
          record.project.update_attributes({ :average_build_time => new_av_time, :build_count => build_count + 1 }, :without_protection => true)
        end
      end
    end
  end # before_update

end

class BuildListObserver < ActiveRecord::Observer
  observe :build_list

  def before_update(record)
    if record.status_changed?
      record.started_at = Time.now if record.status == BuildList::BUILD_STARTED
      if [BuildList::BUILD_ERROR,
          BuildList::SUCCESS,
          BuildList::BUILD_CANCELING,
          BuildList::BUILD_CANCELED].include? record.status
        # stores time interval beetwin build start and finish in seconds
        record.duration = record.current_duration if record.started_at

        if record.status == BuildList::SUCCESS
          # Update project average build time
          build_count = record.project.build_count
          new_av_time = ( record.project.average_build_time * build_count + record.duration ) / ( build_count + 1 )
          record.project.update_attributes({ :average_build_time => new_av_time, :build_count => build_count + 1 }, :without_protection => true)
        end
      end
    end
  end # before_update

end

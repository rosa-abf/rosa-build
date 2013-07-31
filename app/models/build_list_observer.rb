class BuildListObserver < ActiveRecord::Observer
  observe :build_list

  def before_update(record)
    if record.status_changed?
      record.started_at = Time.now if record.status == BuildList::BUILD_STARTED
      if [BuildList::BUILD_ERROR,
          BuildList::SUCCESS,
          BuildList::BUILD_CANCELING,
          BuildList::TESTS_FAILED,
          BuildList::BUILD_CANCELED].include? record.status
        # stores time interval beetwin build start and finish in seconds
        record.duration = record.current_duration if record.started_at

        if record.status == BuildList::SUCCESS
          # Update project average build time
          begin
            statistic = record.project.project_statistics.find_or_create_by_arch_id(record.arch_id)
          rescue ActiveRecord::RecordNotUnique
            retry
          end
          build_count = statistic.build_count
          new_av_time = ( statistic.average_build_time * build_count + record.duration ) / ( build_count + 1 )
          statistic.update_attributes(:average_build_time => new_av_time, :build_count => build_count + 1)
        end
      end
    end
  end # before_update

end

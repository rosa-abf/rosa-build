module BuildListObserver
  extend ActiveSupport::Concern

  included do
    before_update :update_average_build_time
  end

  private

  def update_average_build_time
    if status_changed?
      started_at = Time.now if status == BUILD_STARTED
      if [BUILD_ERROR,
          SUCCESS,
          BUILD_CANCELING,
          TESTS_FAILED,
          BUILD_CANCELED].include? status
        # stores time interval beetwin build start and finish in seconds
        duration = current_duration if started_at

        if status == SUCCESS
          # Update project average build time
          begin
            statistic = project.project_statistics.find_or_create_by_arch_id(arch_id)
          rescue ActiveRecord::RecordNotUnique
            retry
          end
          build_count = statistic.build_count.to_i
          new_av_time = ( statistic.average_build_time * build_count + record.duration.to_i ) / ( build_count + 1 )
          statistic.update_attributes(average_build_time: new_av_time, build_count: build_count + 1)
        end
      end
    end
  end
end

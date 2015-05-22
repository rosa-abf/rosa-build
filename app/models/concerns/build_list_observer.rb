module BuildListObserver
  extend ActiveSupport::Concern

  included do
    before_update :update_average_build_time
    before_update :update_statistic
  end

  private

  def update_statistic
    Statistic.statsd_increment(
      activity_at:  Time.now,
      key:          "#{Statistic::KEY_BUILD_LIST}.#{status}",
      project_id:   project_id,
      user_id:      user_id,
    ) if status_changed?
  end

  def update_average_build_time
    if status_changed?
      self.started_at = Time.now if status == self.class::BUILD_STARTED
      if [self.class::BUILD_ERROR,
          self.class::SUCCESS,
          self.class::BUILD_CANCELING,
          self.class::TESTS_FAILED,
          self.class::BUILD_CANCELED].include? status
        # stores time interval beetwin build start and finish in seconds
        self.duration = current_duration if self.started_at

        if status == self.class::SUCCESS
          # Update project average build time
          begin
            statistic = project.project_statistics.where(arch_id: arch_id).first_or_create
          rescue ActiveRecord::RecordNotUnique
            retry
          end
          build_count = statistic.build_count.to_i
          new_av_time = ( statistic.average_build_time * build_count + duration.to_i ) / ( build_count + 1 )
          statistic.update_attributes(average_build_time: new_av_time, build_count: build_count + 1)
        end
      end
    end
  end
end

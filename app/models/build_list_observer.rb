class BuildListObserver < ActiveRecord::Observer
  PUBLICATION_STATUSES  = [BuildList::BUILD_PUBLISHED, BuildList::FAILED_PUBLISH]
  STATUSES = [BuildServer::BUILD_ERROR, BuildServer::SUCCESS] + PUBLICATION_STATUSES

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
      BuildListObserver.notify_users(record)
    end
  end # before_update

  private

  def self.notify_users(build_list)
    if !build_list.mass_build_id &&
       ( (build_list.auto_publish? && PUBLICATION_STATUSES.include?(build_list.status)) ||
         (!build_list.auto_publish? && STATUSES.include?(build_list.status)) )

      users = []
      if build_list.project # find associated users
        users = build_list.project.all_members.
          select{ |user| user.notifier.can_notify? && user.notifier.new_associated_build? }
      end
      if build_list.user.notifier.can_notify? && build_list.user.notifier.new_build?
        users | [build_list.user]
      end
      users.each do |user|
        UserMailer.build_list_notification(build_list, user).deliver
      end
    end
  end # notify_users
end

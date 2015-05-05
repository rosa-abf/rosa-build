module Feed::BuildList
  extend ActiveSupport::Concern

  included do
    after_update :build_list_notifications
  end

  private

  def build_list_notifications
    if mass_build.blank? && ( # Do not show mass build activity in activity feeds
        status_changed? && [
                              BuildList::BUILD_PENDING,
                              BuildList::BUILD_PUBLISHED,
                              BuildList::SUCCESS,
                              BuildList::BUILD_ERROR,
                              BuildList::FAILED_PUBLISH,
                              BuildList::TESTS_FAILED
                            ].include?(status)
      )

      updater = publisher || user
      (project.all_members | [publisher]).compact.each do |recipient|
        ActivityFeed.create(
          user:            recipient,
          kind:            'build_list_notification',
          project_owner:   project.owner_uname,
          project_name:    project.name,
          creator_id:      updater.id,
          data: {
            build_list_id: id,
            status:        status,
            updated_at:    updated_at,
            project_id:    project_id,
            creator_name:  updater.name,
            creator_email: updater.email
          }
        )
      end

    end
  end

end
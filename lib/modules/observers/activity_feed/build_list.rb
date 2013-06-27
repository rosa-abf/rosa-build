# -*- encoding : utf-8 -*-
module Modules::Observers::ActivityFeed::BuildList
  extend ActiveSupport::Concern

  included do
    after_update :build_list_notifications
  end

  private

  def build_list_notifications
    if mass_build.blank? && ( # Do not show mass build activity in activity feeds
        status_changed? && [
                              BUILD_PUBLISHED,
                              SUCCESS,
                              BUILD_ERROR,
                              FAILED_PUBLISH,
                              TESTS_FAILED
                            ].include?(status) ||
        status == BUILD_PENDING && bs_id_changed?
      )

      updater = publisher || user
      project.admins.each do |recipient|
        ActivityFeed.create(
          :user => recipient,
          :kind => 'build_list_notification',
          :data => {
            :task_num       => bs_id,
            :build_list_id  => id,
            :status         => status,
            :updated_at     => updated_at,
            :project_id     => project_id,
            :project_name   => project.name,
            :project_owner  => project.owner.uname,
            :user_name      => updater.name,
            :user_email     => updater.email,
            :user_id        => updater.id
          }
        )
      end

    end
  end

end
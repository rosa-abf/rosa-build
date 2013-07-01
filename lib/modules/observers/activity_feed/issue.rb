# -*- encoding : utf-8 -*-
module Modules::Observers::ActivityFeed::Issue
  extend ActiveSupport::Concern

  included do
    after_commit :new_issue_notifications, :on => :create
    after_update -> { send_assign_notifications(:update) }
  end

  private

  def new_issue_notifications
    collect_recipients.each do |recipient|
      next if user_id == recipient.id
      UserMailer.new_issue_notification(self, recipient).deliver if recipient.notifier.can_notify && recipient.notifier.new_issue
      ActivityFeed.create(
        :user => recipient,
        :kind => 'new_issue_notification',
        :data => {
          :user_name        => user.name,
          :user_email       => user.email,
          :user_id          => user_id,
          :issue_serial_id  => serial_id,
          :issue_title      => title,
          :project_id       => project.id,
          :project_name     => project.name,
          :project_owner    => project.owner.uname
        }
      )
    end
    send_assign_notifications
  end

  def send_assign_notifications(action = :create)
    if assignee_id && assignee_id_changed?
      if assignee.notifier.issue_assign && assignee.notifier.can_notify
        user_mailer_action = action == :create ? :new_issue_notification : :issue_assign_notification
        UserMailer.send(user_mailer_action, self, assignee).deliver
      end
      ActivityFeed.create(
        :user => assignee,
        :kind => 'issue_assign_notification',
        :data => {
          :user_name        => assignee.name,
          :user_email       => assignee.email,
          :issue_serial_id  => serial_id,
          :issue_title      => title,
          :project_id       => project.id,
          :project_name     => project.name,
          :project_owner    => project.owner.uname
        }
      )
    end
    project.hooks.each{ |h| h.receive_issues(self, action) } if action == :create || status_changed?
    # dont remove outdated issues link
    Comment.create_link_on_issues_from_item(self)
  end

end
module Feed::Issue
  extend ActiveSupport::Concern

  included do
    after_commit :new_issue_notifications,    on: :create

    after_commit :send_assign_notifications,  on: :create, if: ->(i) { i.assignee }
    after_update :send_assign_notifications

    after_commit :send_hooks, on: :create
    after_update -> { send_hooks(:update) }, if: ->(i) { i.previous_changes['status'].present? }
  end

  private

  def new_issue_notifications
    collect_recipients.each do |recipient|
      if user_id != recipient.id && recipient.notifier.can_notify &&
         recipient.notifier.new_issue && assignee_id != recipient.id
        UserMailer.new_issue_notification(id, recipient.id).deliver
      end
      ActivityFeed.create(
        user:              recipient,
        kind:              'new_issue_notification',
        project_owner:     project.owner_uname,
        project_name:      project.name,
        creator_id:        user_id,
        data: {
          creator_name:    user.name,
          creator_email:   user.email,
          issue_serial_id: serial_id,
          issue_title:     title,
          project_id:      project.id
        }
      )
    end
    ::Comment.create_link_on_issues_from_item(self)
  end

  def send_assign_notifications
    return if @skip_assign_notifications
    @skip_assign_notifications = true
    if assignee_id && assignee_id_changed?
      if assignee.notifier.issue_assign && assignee.notifier.can_notify
        UserMailer.issue_assign_notification(self, assignee).deliver
      end
      ActivityFeed.create(
        user: assignee,
        kind: 'issue_assign_notification',
        project_owner: project.owner_uname,
        project_name:  project.name,
        data: {
          user_name:       assignee.name,
          user_email:      assignee.email,
          issue_serial_id: serial_id,
          issue_title:     title,
          project_id:      project.id
        }
      )
    end
    # dont remove outdated issues link
    ::Comment.create_link_on_issues_from_item(self) if title_changed? || body_changed?
  end

  def send_hooks(action = :create)
    project.hooks.each{ |h| h.receive_issues(self, action) }
  end
end

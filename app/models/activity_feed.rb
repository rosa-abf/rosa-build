class ActivityFeed < ActiveRecord::Base

  CODE    = ['git_delete_branch_notification', 'git_new_push_notification', 'new_comment_commit_notification']
  TRACKER = ['issue_assign_notification', 'new_comment_notification', 'new_issue_notification']
  BUILD   = ['build_list_notification']
  WIKI    = ['wiki_new_commit_notification']

  belongs_to :user
  serialize :data

  default_scope { order created_at: :desc }
  scope :outdated, -> { offset(100) }

  self.per_page = 10

  def partial
    'home/partials/' + self.kind
  end
end

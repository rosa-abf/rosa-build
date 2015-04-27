class ActivityFeed < ActiveRecord::Base

  CODE    = %w(git_delete_branch_notification git_new_push_notification new_comment_commit_notification)
  TRACKER = %w(issue_assign_notification new_comment_notification new_issue_notification)
  BUILD   = %w(build_list_notification)
  WIKI    = %w(wiki_new_commit_notification)

  belongs_to :user
  belongs_to :creator, class_name: 'User'
  serialize  :data

  # attr_accessible :user, :kind, :data, :project_owner, :project_name, :creator_id

  default_scope { order created_at: :desc }
  scope :outdated,        -> { offset(1000) }
  scope :by_project_name, ->(name)  { where(project_name: name)   if name.present?  }
  scope :by_owner_uname,  ->(owner) { where(project_owner: owner) if owner.present? }

  self.per_page = 20

  def partial
    "home/partials/#{self.kind}"
  end
end

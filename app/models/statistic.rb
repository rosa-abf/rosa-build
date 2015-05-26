class Statistic < ActiveRecord::Base
  KEYS = [
    KEY_COMMIT                      = 'commit',
    KEY_BUILD_LIST                  = 'build_list',
    KEY_BUILD_LIST_BUILD_STARTED    = "#{KEY_BUILD_LIST}.#{BuildList::BUILD_STARTED}",
    KEY_BUILD_LIST_SUCCESS          = "#{KEY_BUILD_LIST}.#{BuildList::SUCCESS}",
    KEY_BUILD_LIST_BUILD_ERROR      = "#{KEY_BUILD_LIST}.#{BuildList::BUILD_ERROR}",
    KEY_BUILD_LIST_BUILD_PUBLISHED  = "#{KEY_BUILD_LIST}.#{BuildList::BUILD_PUBLISHED}",
    KEY_ISSUE                       = 'issue',
    KEY_ISSUES_OPEN                 = "#{KEY_ISSUE}.#{Issue::STATUS_OPEN}",
    KEY_ISSUES_REOPEN               = "#{KEY_ISSUE}.#{Issue::STATUS_REOPEN}",
    KEY_ISSUES_CLOSED               = "#{KEY_ISSUE}.#{Issue::STATUS_CLOSED}",
    KEY_PULL_REQUEST                = 'pull_request',
    KEY_PULL_REQUESTS_OPEN          = "#{KEY_PULL_REQUEST}.#{PullRequest::STATUS_OPEN}",
    KEY_PULL_REQUESTS_MERGED        = "#{KEY_PULL_REQUEST}.#{PullRequest::STATUS_MERGED}",
    KEY_PULL_REQUESTS_CLOSED        = "#{KEY_PULL_REQUEST}.#{PullRequest::STATUS_CLOSED}",
  ]

  belongs_to :user
  belongs_to :project

  validates :user_id,
    uniqueness: { scope: [:project_id, :key, :activity_at] },
    presence: true

  validates :email,
    presence: true

  validates :project_id,
    presence: true

  validates :project_name_with_owner,
    presence: true

  validates :key,
    presence: true

  validates :counter,
    presence: true

  validates :activity_at,
    presence: true

  scope :for_period,            -> (start_date, end_date) {
    where(activity_at: (start_date..end_date))
  }
  scope :for_users,             -> (user_ids)   {
    where(user_id: user_ids) if user_ids.present?
  }
  scope :for_groups,            -> (group_ids)  {
    where(["project_id = ANY (
        ARRAY (
          SELECT target_id
          FROM relations
          INNER JOIN projects ON projects.id = relations.target_id
          WHERE relations.target_type = 'Project' AND
          projects.owner_type = 'Group' AND
          relations.actor_type = 'Group' AND
          relations.actor_id IN (:groups)
        )
      )", { groups: group_ids }
    ]) if group_ids.present?
  }

  scope :build_lists_started,   -> { where(key: KEY_BUILD_LIST_BUILD_STARTED) }
  scope :build_lists_success,   -> { where(key: KEY_BUILD_LIST_SUCCESS) }
  scope :build_lists_error,     -> { where(key: KEY_BUILD_LIST_BUILD_ERROR) }
  scope :build_lists_published, -> { where(key: KEY_BUILD_LIST_BUILD_PUBLISHED) }
  scope :commits,               -> { where(key: KEY_COMMIT) }
  scope :issues_open,           -> { where(key: KEY_ISSUES_OPEN) }
  scope :issues_reopen,         -> { where(key: KEY_ISSUES_REOPEN) }
  scope :issues_closed,         -> { where(key: KEY_ISSUES_CLOSED) }
  scope :pull_requests_open,    -> { where(key: KEY_PULL_REQUESTS_OPEN) }
  scope :pull_requests_merged,  -> { where(key: KEY_PULL_REQUESTS_MERGED) }
  scope :pull_requests_closed,  -> { where(key: KEY_PULL_REQUESTS_CLOSED) }


  def self.now_statsd_increment(activity_at: nil, user_id: nil, project_id: nil, key: nil, counter: 1)
    # Truncates a DateTime to the minute
    activity_at = activity_at.utc.change(min: 0)
    user        = User.find user_id
    project     = Project.find project_id
    Statistic.create(
      user_id:                  user_id,
      email:                    user.email,
      project_id:               project_id,
      project_name_with_owner:  project.name_with_owner,
      key:                      key,
      activity_at:              activity_at
    )
  rescue ActiveRecord::RecordNotUnique
    # Do nothing, see: ensure
  ensure
    Statistic.where(
      user_id:      user_id,
      project_id:   project_id,
      key:          key,
      activity_at:  activity_at
    ).update_all(['counter = counter + ?', counter]) if user_id.present? && project_id.present?
  end

  def self.statsd_increment(options = {})
    Statistic.perform_later(:middle, :now_statsd_increment, options)
  end

end

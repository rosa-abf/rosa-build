class Statistic < ActiveRecord::Base
  KEYS = [
    KEY_COMMIT                      = 'commit',
    KEY_BUILD_LIST                  = 'build_list',
    KEY_BUILD_LIST_BUILD_STARTED    = "#{KEY_BUILD_LIST}.#{BuildList::BUILD_STARTED}",
    KEY_BUILD_LIST_SUCCESS          = "#{KEY_BUILD_LIST}.#{BuildList::SUCCESS}",
    KEY_BUILD_LIST_BUILD_ERROR      = "#{KEY_BUILD_LIST}.#{BuildList::BUILD_ERROR}",
    KEY_BUILD_LIST_BUILD_PUBLISHED  = "#{KEY_BUILD_LIST}.#{BuildList::BUILD_PUBLISHED}"
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

  attr_accessible :user_id,
                  :email,
                  :project_id,
                  :project_name_with_owner,
                  :key,
                  :counter,
                  :activity_at

  scope :for_period,            -> (start_date, end_date) { where(activity_at: (start_date..end_date)) }

  scope :build_lists_started,   -> { where(key: KEY_BUILD_LIST_BUILD_STARTED) }
  scope :build_lists_success,   -> { where(key: KEY_BUILD_LIST_SUCCESS) }
  scope :build_lists_error,     -> { where(key: KEY_BUILD_LIST_BUILD_ERROR) }
  scope :build_lists_published, -> { where(key: KEY_BUILD_LIST_BUILD_PUBLISHED) }
  scope :commits,               -> { where(key: KEY_COMMIT) }



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
    ).update_all(['counter = counter + ?', counter])
  end

  def self.statsd_increment(options = {})
    Statistic.perform_later(:middle, :now_statsd_increment, options)
  end

end

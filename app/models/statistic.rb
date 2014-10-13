class Statistic < ActiveRecord::Base
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

  scope :build_lists_started,   -> { where(key: "build_list.#{BuildList::BUILD_STARTED}") }
  scope :build_lists_success,   -> { where(key: "build_list.#{BuildList::SUCCESS}") }
  scope :build_lists_error,     -> { where(key: "build_list.#{BuildList::BUILD_ERROR}") }
  scope :build_lists_published, -> { where(key: "build_list.#{BuildList::BUILD_PUBLISHED}") }



  def self.now_statsd_increment(activity_at: nil, user_id: nil, project_id: nil, key: nil)
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
  ensure
    Statistic.where(
      user_id:      user_id,
      project_id:   project_id,
      key:          key,
      activity_at:  activity_at
    ).update_all('counter = counter + 1')
  end

  # TODO: remove later
  def self.fill_in_build_lists
    BuildList.find_each do |bl|
      Statistic.now_statsd_increment({
        activity_at:  bl.created_at,
        key:          "build_list.#{BuildList::BUILD_STARTED}",
        project_id:   bl.project_id,
        user_id:      bl.user_id,
      })
      Statistic.now_statsd_increment({
        activity_at:  bl.updated_at,
        key:          "build_list.#{bl.status}",
        project_id:   bl.project_id,
        user_id:      bl.user_id,
      })
    end
  end

  def self.statsd_increment(options = {})
    Statistic.perform_later(:middle, :now_statsd_increment, options)
  end

end

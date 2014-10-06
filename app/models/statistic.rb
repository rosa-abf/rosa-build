class Statistic < ActiveRecord::Base
  # TYPES = %w()

  belongs_to :user
  belongs_to :project

  validates :user_id,
    uniqueness: { scope: [:project_id, :type, :activity_at] },
    presence: true

  validates :email,
    presence: true

  validates :project_id, 
    presence: true

  validates :project_name_with_owner,
    presence: true

  validates :type,
    presence: true

  validates :counter,
    presence: true

  validates :activity_at,
    presence: true

  attr_accessible :user_id,
                  :email,
                  :project_id,
                  :project_name_with_owner,
                  :type,
                  :counter,
                  :activity_at

  def self.now_statsd_increment(options = {})
    # Truncates a DateTime to the minute
    activity_at = options[:activity_at].utc.change(min: 0)
    user        = User.find options[:user_id]
    project     = Project.find options[:project_id]
    Statistic.create(
      user:                     user,
      email:                    user.email,
      project:                  project,
      project_name_with_owner:  project.name_with_owner,
      type:                     options[:type],
      activity_at:              activity_at
    )
  ensure
    Statistic.where(
      user_id:      options[:user_id],
      project_id:   options[:project_id],
      type:         options[:type],
      activity_at:  activity_at
    ).update_all('counter = counter + ?', options[:counter])
  end

  def self.statsd_increment(options = {})
    Statistic.perform_later(:middle, :now_statsd_increment, options)
  end

end

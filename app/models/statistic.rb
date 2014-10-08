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

  scope :for_period,        -> (start_date, end_date) { where(activity_at: (start_date..end_date)) }

  def self.build_lists(range_start, range_end, unit)
    items = select("SUM(counter) as count, date_trunc('#{ unit }', activity_at) as activity_at").
      group("date_trunc('#{ unit }', activity_at)").order('activity_at')


    build_started   = items.where(key: "build_list.#{BuildList::BUILD_STARTED}")
    success         = items.where(key: "build_list.#{BuildList::SUCCESS}")
    build_error     = items.where(key: "build_list.#{BuildList::BUILD_ERROR}")
    build_published = items.where(key: "build_list.#{BuildList::BUILD_PUBLISHED}")

    {
      build_started:    prepare_collection(build_started, range_start, range_end, unit),
      success:          prepare_collection(success, range_start, range_end, unit),
      build_error:      prepare_collection(build_error, range_start, range_end, unit),
      build_published:  prepare_collection(build_published, range_start, range_end, unit),
    }
  end

  def self.prepare_collection(items, range_start, range_end, unit)
    format = unit == :hour ? '%F %H:00:00' : '%F'
    items = items.map do |item|
      { x: item.activity_at.strftime(format), y: item.count }
    end
    if items.size == 0
      start = range_start
      while start <= range_end
        items.unshift({ x: start.strftime(format), y: 0 })
        start += 1.send(unit)
      end
    end
    if items[0].try(:[], :x) != range_start.strftime(format)
      items.unshift({ x: range_start.strftime(format), y: 0 })
    end
    if items[-1].try(:[], :x) != range_end.strftime(format)
      items << { x: range_end.strftime(format), y: 0 }
    end
    items
  end

  protected

  def format
    @format ||= case period.unit
      when 'hour'
        '%F %H:00:00'
      else # 'day', 'month'
        '%F'
      end
  end

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

  def self.fill_in
    BuildList.find_each do |bl|
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

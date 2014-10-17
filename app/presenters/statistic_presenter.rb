class StatisticPresenter < ApplicationPresenter

  attr_accessor :range_start, :range_end, :unit

  def initialize(range_start: nil, range_end: nil, unit: nil)
    @range_start  = range_start
    @range_end    = range_end
    @unit         = unit
  end

  def as_json(options = nil)
    {
      build_lists: {
        build_started:          prepare_collection(build_lists_started),
        success:                prepare_collection(build_lists_success),
        build_error:            prepare_collection(build_lists_error),
        build_published:        prepare_collection(build_lists_published),

        build_started_count:    build_lists_started.sum(&:count),
        success_count:          build_lists_success.sum(&:count),
        build_error_count:      build_lists_error.sum(&:count),
        build_published_count:  build_lists_published.sum(&:count),
      },
      commits: {
        chart:                  prepare_collection(commits_chart),
        commits_count:          commits_chart.sum(&:count)
      }
    }
  end

  private

  def scope
    @scope ||= Statistic.for_period(range_start, range_end).
      select("SUM(counter) as count, date_trunc('#{ unit }', activity_at) as activity_at").
      group("date_trunc('#{ unit }', activity_at)").order('activity_at')
  end

  def commits_chart
    @commits_chart ||= scope.commits.to_a
  end

  def build_lists_started
    @build_lists_started ||= scope.build_lists_started.to_a
  end

  def build_lists_success
    @build_lists_success ||= scope.build_lists_success.to_a
  end

  def build_lists_error
    @build_lists_error ||= scope.build_lists_error.to_a
  end

  def build_lists_published
    @build_lists_published ||= scope.build_lists_published.to_a
  end

  def prepare_collection(items)
    data  = []
    to    = range_start
    while to <= range_end
      from  = to - 1.send(unit)
      y     = items.find{ |i| i.activity_at > from && i.activity_at <= to }.try(:count)
      data << { x: to.strftime(format), y: y || 0 }
      to += 1.send(unit)
    end
    data
  end

  def format
    @format ||= unit == :hour ? '%H:%M' : '%Y-%m-%d'
  end

end

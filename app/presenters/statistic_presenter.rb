class StatisticPresenter < ApplicationPresenter

  attr_accessor :range_start, :range_end, :unit, :users_or_groups

  def initialize(range_start: nil, range_end: nil, unit: nil, users_or_groups: nil)
    @range_start      = range_start
    @range_end        = range_end
    @unit             = unit
    @users_or_groups  = users_or_groups.to_s.split(/,/).map(&:strip).select(&:present?).first(3)
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
      },
      issues: {
        open:                   prepare_collection(issues_open),
        reopen:                 prepare_collection(issues_reopen),
        closed:                 prepare_collection(issues_closed),

        open_count:             issues_open.sum(&:count),
        reopen_count:           issues_reopen.sum(&:count),
        closed_count:           issues_closed.sum(&:count)
      },
      pull_requests: {
        open:                   prepare_collection(pull_requests_open),
        merged:                 prepare_collection(pull_requests_merged),
        closed:                 prepare_collection(pull_requests_closed),

        open_count:             pull_requests_open.sum(&:count),
        merged_count:           pull_requests_merged.sum(&:count),
        closed_count:           pull_requests_closed.sum(&:count)
      }
    }
  end

  private

  def user_ids
    @user_ids ||= User.where(uname: users_or_groups).pluck(:id)
  end

  def group_ids
    @group_ids ||= Group.where(uname: users_or_groups).pluck(:id)
  end

  def scope
    @scope ||= Statistic.for_period(range_start, range_end).
      for_users(user_ids).for_groups(group_ids).
      select("SUM(counter) as count, date_trunc('#{ unit }', activity_at) as activity_at").
      group("date_trunc('#{ unit }', activity_at)").order('activity_at')
  end

  def issues_open
    @issues_open ||= scope.issues_open.to_a
  end

  def issues_reopen
    @issues_reopen ||= scope.issues_reopen.to_a
  end

  def issues_closed
    @issues_closed ||= scope.issues_closed.to_a
  end

  def pull_requests_open
    @pull_requests_open ||= scope.pull_requests_open.to_a
  end

  def pull_requests_merged
    @pull_requests_merged ||= scope.pull_requests_merged.to_a
  end

  def pull_requests_closed
    @pull_requests_closed ||= scope.pull_requests_closed.to_a
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

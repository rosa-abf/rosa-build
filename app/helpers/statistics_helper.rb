module StatisticsHelper
  RANGES = %w(
    twenty_four_hours
    last_7_days
    last_30_days
    last_60_days
    last_90_days
    last_180_days
    last_year
    custom
  )

  def statistics_range_options
    options_for_select(
      RANGES.map { |r| [I18n.t(r, scope: 'statistics.helper.period'), r] }
    )
  end

end

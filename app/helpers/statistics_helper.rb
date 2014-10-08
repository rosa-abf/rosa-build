module StatisticsHelper

  def statistics_range_options
    options_for_select(
      StatisticsController::RANGES.map { |r| [I18n.t(r, scope: 'statistics.helper.period'), r] }
    )
  end

end

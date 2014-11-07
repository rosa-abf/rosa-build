class StatisticsController < ApplicationController
  layout 'bootstrap'

  RANGES = [
    RANGE_TWENTY_FOUR_HOURS = 'twenty_four_hours',
    RANGE_LAST_7_DAYS       = 'last_7_days',
    RANGE_LAST_30_DAYS      = 'last_30_days',
    RANGE_LAST_60_DAYS      = 'last_60_days',
    RANGE_LAST_90_DAYS      = 'last_90_days',
    RANGE_LAST_180_DAYS     = 'last_180_days',
    RANGE_LAST_YEAR         = 'last_year',
    RANGE_CUSTOM            = 'custom',
  ]

  def index
    respond_to do |format|
      format.html
      format.json do
        init_variables
        render json: StatisticPresenter.new(
          range_start:      @range_start,
          range_end:        @range_end,
          unit:             @unit,
          users_or_groups:  params[:users_or_groups]
        )
      end
    end
  end

  private

  def init_variables
    case params[:range]
    when RANGE_TWENTY_FOUR_HOURS
      @range_end    = Time.now.utc
      @range_start  = @range_end - 1.day
      @unit         = :hour
    when RANGE_LAST_7_DAYS
      @range_end    = Date.today
      @range_start  = @range_end - 7.days
      @unit         = :day
    when RANGE_LAST_30_DAYS
      @range_end    = Date.today
      @range_start  = @range_end - 30.days
      @unit         = :day
    when RANGE_LAST_60_DAYS
      @range_end    = Date.today
      @range_start  = @range_end - 30.days
      @unit         = :day
    when RANGE_LAST_90_DAYS
      @range_end    = Date.today
      @range_start  = @range_end - 90.days
      @unit         = :day
    when RANGE_LAST_180_DAYS
      @range_end    = Date.today
      @range_start  = @range_end - 180.days
      @unit         = :month
    when RANGE_LAST_YEAR
      @range_end    = Date.today
      @range_start  = @range_end - 1.year
      @unit         = :month
    when RANGE_CUSTOM
      @range_start  = Time.zone.parse(params[:range_start]).utc
      @range_end    = Time.zone.parse(params[:range_end]).utc
      diff          = @range_end - @range_start
      @unit         =
        if diff <= 24.hours
          :hour
        elsif diff <= 90.days
          :day
        else
          :month
        end
    else
      raise ActiveRecord::RecordNotFound
    end
  rescue ArgumentError
    raise ActiveRecord::RecordNotFound
  end

end
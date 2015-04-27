module TimeLiving
  extend ActiveSupport::Concern

  included do

    validates :time_living, numericality: { only_integer: true }, presence: true

    validate -> {
      # MIN_TIME_LIVING <= time_living <= MAX_TIME_LIVING or
      # 2 min <= time_living <= 12 hours
      # time_living in seconds
      min = self.class.const_defined?(:MIN_TIME_LIVING) ? self.class::MIN_TIME_LIVING : 120
      max = self.class.const_defined?(:MAX_TIME_LIVING) ? self.class::MAX_TIME_LIVING : 43200
      if min > time_living.to_i || time_living.to_i > max
        errors.add :time_living,
                   I18n.t('flash.time_living.numericality_error', min: (min / 60), max: (max / 60))
      end
    }

    before_validation :convert_time_living
    # attr_accessible :time_living
  end

  protected

  def convert_time_living
    self.time_living = time_living.to_i * 60 if time_living_was.to_i != time_living.to_i
  end
end

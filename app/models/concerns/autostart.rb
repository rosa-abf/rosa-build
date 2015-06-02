module Autostart
  extend ActiveSupport::Concern

  ONCE_A_12_HOURS = 0
  ONCE_A_DAY      = 1
  ONCE_A_WEEK     = 2

  AUTOSTART_STATUSES        = [ONCE_A_12_HOURS, ONCE_A_DAY, ONCE_A_WEEK]
  HUMAN_AUTOSTART_STATUSES  = {
    ONCE_A_12_HOURS => :once_a_12_hours,
    ONCE_A_DAY      => :once_a_day,
    ONCE_A_WEEK     => :once_a_week
  }

  included do
    validates :autostart_status, numericality: true,
      inclusion: {in: AUTOSTART_STATUSES}, allow_blank: true
  end

  def human_autostart_status
    self.class.human_autostart_status(autostart_status)
  end

  module ClassMethods
    def human_autostart_status(autostart_status)
      I18n.t("layout.products.autostart_statuses.#{HUMAN_AUTOSTART_STATUSES[autostart_status]}")
    end
  end
end

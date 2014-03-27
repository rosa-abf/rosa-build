module EventLoggable
  extend ActiveSupport::Concern

  included do
    after_create :log_creation_event
    after_destroy :log_destroying_event
  end

  private

  def log_creation_event
    ActiveSupport::Notifications.instrument(self.class.name, eventable: self)
  end

  def log_before_update
    case self.class.to_s
    when 'BuildList'
      if status_changed? and [BuildList::BUILD_CANCELED, BuildList::BUILD_PUBLISHED].include?(status)
        ActiveSupport::Notifications.instrument("event_log.observer", eventable: self)
      end
    when 'Platform'
      if self.visibility_changed?
        ActiveSupport::Notifications.instrument "event_log.observer", eventable: self,
          message: I18n.t("activeself.attributes.platform.visibility_types.#{visibility}")
      end
    end
  end

  def log_destroying_event
    ActiveSupport::Notifications.instrument(self.class.name, eventable: self)
  end
end

class EventLogObserver < ActiveRecord::Observer
  observe :user, :platform, :repository, :project, :product, :build_list

  def after_create(record)
    ActiveSupport::Notifications.instrument("event_log.observer", :object => record)
  end

  # def after_update(record)
  #   ActiveSupport::Notifications.instrument("event_log.observer", :object => record)
  # end

  def after_destroy(record)
    ActiveSupport::Notifications.instrument("event_log.observer", :object => record)
  end
end

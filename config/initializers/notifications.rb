Warden::Manager.after_authentication do |user,auth,opts| # after_set_user, :except => fetch
  ActiveSupport::Notifications.instrument("event_log.observer", :object => user)
end

Warden::Manager.before_failure do |env, opts|
  # raise env.inspect
  ActiveSupport::Notifications.instrument("event_log.observer", :kind => 'error',
    :message => env['action_dispatch.request.request_parameters']['user'].delete_if{|k,v| k == 'password'}.inspect)
end

Warden::Manager.before_logout do |user,auth,opts|
  ActiveSupport::Notifications.instrument("event_log.observer", :object => user)
end

ActiveSupport::Notifications.subscribe "event_log.observer" do |name, start, finish, id, payload|
  if c = EventLog.current_controller
    EventLog.create_with_current_controller :kind => (payload[:kind].presence || 'info'), :message => payload[:message].presence,
                                            :object => payload[:object], :object_name => payload[:object_name].presence
  end
end

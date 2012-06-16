require 'resque/server'
require 'resque/status_server'

::ResqueServer = ::Resque::Server # need for CanCan

Resque::Mailer.default_queue_name = 'notifications'
Resque::Mailer.excluded_environments = [:test]

unless Rails.env.test?
  PerformLater.config.enabled = true # this will default to false if unset
end

Resque::Plugins::Status::Hash.expire_in = (24 * 60 * 60) # 24hrs in seconds

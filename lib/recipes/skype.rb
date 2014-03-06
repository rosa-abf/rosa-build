require 'skype'

Capistrano::Configuration.instance(:must_exist).load do
  Skype.config app_name: 'test-message'
  set :skype_send_notification, true

  namespace :skype do
    task :trigger_notification do
      set :skype_send_notification, true if !dry_run
    end

    task :configure_for_migrations do
      set :skype_with_migrations, ' (with migrations)'
    end

    task :notify_deploy_started do
      if skype_send_notification

        environment_string = env
        if self.respond_to?(:stage)
          environment_string = "#{stage} (#{env})"
        end

        on_rollback do
          send("Cancelled deployment of #{deployment_name} to #{environment_string}.")
          send('#'*60)
        end
        send('#'*60)
        send("Deploying #{deployment_name} to #{environment_string}#{fetch(:skype_with_migrations, '')}.")
      end
    end

    task :notify_deploy_finished do
      if skype_send_notification

        environment_string = env
        if self.respond_to?(:stage)
          environment_string = "#{stage} (#{env})"
        end

        send("Finished deploying #{deployment_name} to #{environment_string}#{fetch(:skype_with_migrations, '')}.")
        send('#'*60)
      end
    end

    def send(message)
      set :skype_client, Skype.chats.find { |c| c.topic == fetch(:skype_topic, '') } if fetch(:skype_client, nil).nil?

      begin
        skype_client.post(message)
      rescue => e
        puts e.message
        puts e.backtrace
      end
    end

    def deployment_name
      if fetch(:branch, nil)
        name = "#{application}/#{branch}"
        name += " (revision #{real_revision[0..7]})" if real_revision
        name
      else
        application
      end
    end

    def message_notification
      fetch(:skype_announce, false)
    end

    def env
      fetch(:skype_env, fetch(:rack_env, fetch(:rails_env, "production")))
    end
  end

  before "deploy", "skype:trigger_notification"
  before "deploy:update_code", "skype:notify_deploy_started"
  after  "deploy", "skype:notify_deploy_finished"
  after  "deploy:migrations", "skype:notify_deploy_finished"
end

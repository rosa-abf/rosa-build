Capistrano::Configuration.instance(:must_exist).load do
  namespace :bluepill do
    set(:bluepill_config) { File.join release_path, 'config', 'production.pill' }

    desc "Stop processes that bluepill is monitoring and quit bluepill"
    task :quit, :roles => [:app] do
      sudo "bundle exec bluepill stop APP_NAME=#{fetch :application}"
      sudo "bundle exec bluepill quit APP_NAME=#{fetch :application}"
    end

    desc "Load bluepill configuration and start it"
    task :start, :roles => [:app] do
      sudo "bundle exec bluepill load #{bluepill_config} APP_NAME=#{fetch :application}"
    end

    desc "Prints bluepills monitored processes statuses"
    task :status, :roles => [:app] do
      sudo "bundle exec bluepill status APP_NAME=#{fetch :application}"
    end
  end
end

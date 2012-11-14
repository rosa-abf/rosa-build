namespace :pull_requests do

  desc 'Remove temporary git repos for pull requests'
  task :clear => :environment do
    Dir.chdir(File.join(APP_CONFIG['git_path'], 'pull_requests', 'tmp')) do
      say "Removing repos older one day:"
      say `find -mindepth 2 -maxdepth 2 -type d -mtime +0`
      `find -mindepth 2 -maxdepth 2 -type d -mtime +0 | xargs rm -rf`
      say '-----'
      say "Removing empty dir:"
      say `find -mindepth 2 -maxdepth 2 -type d -empty`
      `find -mindepth 2 -maxdepth 2 -type d -empty -delete`
      say 'done!'
    end
  end
end

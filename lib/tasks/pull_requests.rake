namespace :pull_requests do

  desc 'Remove temporary git repos for pull requests'
  task clear: :environment do
    Dir.chdir(File.join(APP_CONFIG['git_path'], 'temp_pull_requests')) do
      say "Removing repos older one day:"
      say `find -mindepth 3 -maxdepth 3 -type d -mtime +0`
      `find -mindepth 3 -maxdepth 3 -type d -mtime +0 | xargs rm -rf`
      say '-----'
      say "Removing empty dir:"
      say `find -maxdepth 2 -type d -empty`
      `find -maxdepth 2 -type d -empty -delete`
      say 'done!'
    end
  end
end

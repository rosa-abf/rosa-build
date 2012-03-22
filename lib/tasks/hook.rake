namespace :hook do
  desc "Inserting hook to all repos"
  task :install => :environment do
    is_production = ENV['RAILS_ENV'] == 'production'
    say "Generate temporary file..."
    hook = File.join(::Rails.root.to_s, 'tmp', "post-receive-hook")
    FileUtils.cp(File.join(::Rails.root.to_s, 'bin', "post-receive-hook.partial"), hook)
    File.open(hook, 'a') do |f|
      s = "\n  /bin/bash -l -c \"cd #{is_production ? '/srv/rosa_build/current' : Rails.root.to_s} && #{is_production ? 'RAILS_ENV=production' : ''} bundle exec rails runner 'Project.delay.process_hook(\\\"$owner\\\", \\\"$reponame\\\", \\\"$newrev\\\", \\\"$oldrev\\\", \\\"$ref\\\", \\\"$newrev_type\\\", \\\"$oldrev_type\\\")'\""
      s << " > /dev/null 2>&1" if is_production
      s << "\ndone\n"
      f.write(s)
      f.chmod(0755)
    end

    say "Install process.."
    count = 0
    projects = ENV['project_id'] ? Project.where(:id => eval(ENV['project_id'])) : Project
    projects.where('created_at >= ?', Time.now.ago(ENV['period'] ? eval(ENV['period']) : 100.years)).each do |project|
      hook_file = File.join(project.path, 'hooks', 'post-receive')
      FileUtils.copy_entry(hook, hook_file, false, false, true)
      count = count + 1
    end
    say "Writing to #{count.to_s} repo(s)"
    say "Removing temporary file"
    FileUtils.rm_rf(hook)
  end

  desc "remove git hook from all repos"
  task :remove => :environment do
    say "process.."
    count = 0
    projects = ENV['project_id'] ? Project.where(:id => eval(ENV['project_id'])) : Project
    projects.where('created_at >= ?', Time.now.ago(ENV['period'] ? eval(ENV['period']) : 100.years)).each do |project|
      FileUtils.rm_rf File.join(project.path, 'hooks', 'post-receive')
      count = count + 1
    end
    say "Done! Removing from #{count.to_s} repo(s)"
  end
end

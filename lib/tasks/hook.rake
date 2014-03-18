namespace :hook do
  desc "Inserting hook to all repos"
  task install: :environment do
    hook = "/home/#{APP_CONFIG['shell_user']}/gitlab-shell/hooks/post-receive"
    say "Install process.."
    count, projects = 0, Project.all
    projects = projects.where(id: ENV['PROJECT_ID']) if ENV['PROJECT_ID']
    projects.each do |project|
      next unless Dir.exist? project.path
      hook_file = File.join(project.path, 'hooks', 'post-receive')
      FileUtils.rm_rf hook_file
      begin
        FileUtils.ln_sf(hook, hook_file)
        count = count + 1
      rescue Exception => e
        say "----\nCatching exception with project #{project.id}"
        say e.message
        say '----'
      end
    end
    say "Writing to #{count.to_s} repo(s)"
  end

  desc "remove git hook from all repos"
  task remove: :environment do
    say "process.."
    count, projects = 0, Project.all
    projects = projects.where(id: ENV['PROJECT_ID']) if ENV['PROJECT_ID']
    projects.each do |project|
      FileUtils.rm_rf File.join(project.path, 'hooks', 'post-receive')
      count = count + 1
    end
    say "Done! Removing from #{count.to_s} repo(s)"
  end
end

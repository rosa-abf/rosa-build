namespace :hook do
  desc "Inserting hook to all repos"
  task :install => :environment do
    origin_hook = File.join(::Rails.root.to_s, 'bin', "post-receive-hook#{ENV['RAILS_ENV'] == 'production' ? '_prod' : '_dev'}")
    say "process.. #{origin_hook}"
    count = 0
    Project.all.each do |project|
      hook_file = File.join(project.path, 'hooks', 'post-receive')
      FileUtils.cp(origin_hook, hook_file)
      count = count + 1
    end
    say "Done! Writing to #{count.to_s} repo(s)"
  end

  desc "remove with git hook"
  task :remove => :environment do
    say "process.."
    count = 0
    Project.all.each { |project| FileUtils.rm_rf File.join(project.path, 'hooks', 'post-receive'); count = count + 1}
    say "Done! Removing from #{count.to_s} repo(s)"
  end
end


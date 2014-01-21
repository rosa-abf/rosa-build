namespace :project do
  desc 'Fix pull requests where was delete the "from project"'
  task fix_orphan_pulls: :environment do
    projects = Project.where('ancestry IS NOT NULL')
    say "Pull requests total count is #{PullRequest.count}"
    PullRequest.all.each_with_index do |pull, ind|
      say "Check pull with id:#{pull.id} (#{ind+1}/#{PullRequest.count})"
      if pull.from_project.present?
        print ' updating...'
        pull.from_project_name = pull.from_project.name
        pull.from_project_owner_uname = pull.from_project.owner.uname
        say pull.save(validate: false) ? 'success' : 'fail!'
      else
        print '  its orphan! updating...'
        parent_path = File.join(APP_CONFIG['git_path'], 'pull_requests', pull.to_project.owner.uname, pull.to_project.name)
        Dir.chdir(parent_path) do
          # Get an owner and project name from the pull dir
          elements = Dir["#{pull.id}-*"].first.split '-' rescue []
          pull.from_project_owner_uname, pull.from_project_name = elements[1], elements[2]
          say pull.save(validate: false) ? 'success' : 'fail!'
        end
      end
    end
  end
end


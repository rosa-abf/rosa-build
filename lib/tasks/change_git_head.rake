namespace :project do

  desc 'Change HEAD at projects where default branch is not master'
  task git_change_head: :environment do
    projects = Project.where("default_branch <> 'master'")
    say "Find #{projects.count} project(s) without master HEAD"
    say "Start working..."
    projects.each do |project|
      `cd #{project.path} && git symbolic-ref HEAD refs/heads/#{project.default_branch}` if project.repo.branches.map(&:name).include?(project.default_branch)
    end
    say 'Done!'
  end
end

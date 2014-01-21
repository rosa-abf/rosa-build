namespace :project do
  desc 'Break the dependency of a repository cloned with --shared on its source repository'
  task git_detach_from_parent: :environment do
    projects = Project.where('ancestry IS NOT NULL')
    say "Total count of the forked projects is #{projects.count}"
    projects.each_with_index do |project, ind|
      Dir.chdir(project.path) do
        say "--Start work with #{project.name_with_owner} (#{ind+1}/#{projects.count})--"
        say (system('git', 'repack', '-a') ? 'Ok!' : 'Something wrong!')
      end
    end
  end
end

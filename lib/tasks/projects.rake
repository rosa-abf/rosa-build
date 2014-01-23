namespace :project do

  namespace :maintainer do
    desc 'Set maintainer to owner (or to owners owner if owner is a group) to projects'
    task set_to_owner: :environment do
      projects = Project.scoped
      count = projects.count
      say "Setting maintainer to all projects (#{count})"
      percent_per_batch = 100 * 1000 / count
      i = 1

      projects.find_in_batches do |batch|
        ActiveRecord::Base.transaction do
          batch.each do |proj|
            maintainer_id = (proj.owner_type == 'User') ? proj.owner_id : proj.owner.owner_id
            proj.maintainer_id = maintainer_id
            proj.save
          end
        end
        say "#{percent_per_batch * i}% done."
        i += 1
      end
      say "100% done"
    end
  end
  task maintainer: 'maintainer:set_to_owner'

end

namespace :projects do
  desc 'Add projects from one platform repository to another'
  task copy_to_repo: :environment do
    source_platform = Platform.find_by_name!(ENV['SRC_PLATFORM'])
    dest_platform   = Platform.find_by_name!(ENV['DST_PLATFORM'])
    source_repo     = source_platform.repositories.find_by_name!(ENV['SRC_REPO'])
    dest_repo       = dest_platform.repositories.find_by_name!(ENV['DST_REPO'])

    say "Add from repo '#{source_platform.name}/#{source_repo.name}' to repo '#{dest_platform.name}/#{dest_repo.name}'."
    source_repo.projects.each do |pr|
      say "project #{pr.name}"
      dest_repo.projects << pr rescue print ' Add to repo failed!'
    end
    say 'DONE'
  end
end
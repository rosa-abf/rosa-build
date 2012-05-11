
namespace :buildlist do
  
  namespace :clear do
    desc 'Remove outdated unpublished BuildLists'
    task :outdated => :environment do
      say "Removing outdated BuildLists"
      outdated = BuildList.outdated
      say "There are #{outdated.count} outdated BuildLists at #{Time.now}"

      BuildList.outdated.destroy_all

      say "Outdated BuildLists was successfully removed"
    end
  end
end

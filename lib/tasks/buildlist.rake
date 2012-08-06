
namespace :buildlist do
  
  namespace :clear do
    desc 'Remove outdated BuildLists and MassBuilds'
    task :outdated => :environment do
      say "Removing outdated BuildLists"
      outdated = BuildList.outdated
      say "There are #{outdated.count} outdated BuildLists at #{Time.now}"
      BuildList.outdated.destroy_all

      say "Removing outdated BuildLists"
      outdated = MassBuild.outdated
      say "There are #{outdated.count} outdated MassBuilds at #{Time.now}"
      MassBuild.outdated.destroy_all

      say "Outdated BuildLists and MassBuilds was successfully removed"
    end
  end
end

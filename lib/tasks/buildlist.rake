
namespace :buildlist do
  
  namespace :clear do
    desc 'Remove outdated unpublished BuildLists'
    task :outdated => :environment do
      say "Removing outdated BuildLists"
      outdated = BuildList.outdated
      say "There are #{outdated.count} outdated BuildLists at #{Time.now}"

      begin
        BuildList.outdated.map(&:destroy)
      rescue Exception => e
        say "There was an error: #{e.message}"
      end

      say "Outdated BuildLists was successfully removed"
    end
  end
end

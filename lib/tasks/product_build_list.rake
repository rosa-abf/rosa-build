
namespace :product_build_list do

  namespace :clear do
    desc 'Remove outdated ProductBuildLists'
    task outdated: :environment do
      say "[#{Time.zone.now}] Removing outdated ProductBuildLists"
      say "[#{Time.zone.now}] There are #{ProductBuildList.outdated.count} outdated ProductBuildLists"
      ProductBuildList.outdated.destroy_all
      say "[#{Time.zone.now}] Outdated BuildLists have been removed"
    end
  end

end

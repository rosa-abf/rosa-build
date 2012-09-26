
namespace :buildlist do

  namespace :clear do
    desc 'Remove outdated BuildLists and MassBuilds'
    task :outdated => :environment do
      say "Removing outdated BuildLists"
      outdated = BuildList.outdated
      say "There are #{outdated.count} outdated BuildLists at #{Time.now}"
      BuildList.outdated.destroy_all

      say "Removing outdated MassBuilds"
      outdated = MassBuild.outdated
      say "There are #{outdated.count} outdated MassBuilds at #{Time.now}"
      MassBuild.outdated.destroy_all

      say "Outdated BuildLists and MassBuilds was successfully removed"
    end
  end

  namespace :packages do
    # TODO Maybe do it in migration, because it's just a single query?
    desc 'Actualize packages for all platforms'
    task :actualize => :environment do

      say "Updating packages"
      packages = BuildList::Package.joins( %q{
        JOIN (
           SELECT
             name            AS j_pn,
             package_type    AS j_pt,
             platform_id     AS j_plid,
             MAX(created_at) AS j_ca
           FROM
             build_list_packages
           GROUP BY
             j_pn, j_pt, j_plid
        ) AS lastmaints
        ON
          j_pn       = name
          AND j_pt   = package_type
          AND j_plid = platform_id
          AND j_ca   = created_at
      } ).update_all(:actual => true)
      say "'Actual' setted to #{packages} packages"
    end
  end
end

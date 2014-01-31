
namespace :buildlist do

  namespace :clear do
    desc 'Remove outdated BuildLists and MassBuilds'
    task outdated: :environment do
      say "[#{Time.zone.now}] Removing outdated BuildLists"
      say "[#{Time.zone.now}] There are #{BuildList.outdated.count} outdated BuildLists"
      counter = 0
      BuildList.outdated.order(:id).find_in_batches(batch_size: 100) do |build_lists|
        build_lists.each do |bl|
          bl.destroy && (counter += 1) if bl.id != bl.last_published.first.try(:id)
        end
      end
      say "[#{Time.zone.now}] #{counter} outdated BuildLists have been removed"

      say "[#{Time.zone.now}] Removing outdated MassBuilds"
      say "[#{Time.zone.now}] There are #{MassBuild.outdated.count} outdated MassBuilds"
      counter = 0
      MassBuild.outdated.each do |mb|
        mb.destroy && (counter += 1) if mb.build_lists.count == 0
      end
      say "[#{Time.zone.now}] #{counter} outdated MassBuilds have been removed"

      say "[#{Time.zone.now}] Outdated BuildLists and MassBuilds was successfully removed"
    end

    desc 'Remove outdated BuildLists with status BUILD_CANCELING'
    task outdated_canceling: :environment do
      say "[#{Time.zone.now}] Removing outdated BuildLists"

      scope = BuildList.for_status(BuildList::BUILD_CANCELING).
        for_notified_date_period(nil, Time.zone.now - 3.hours)

      say "[#{Time.zone.now}] There are #{scope.count} outdated BuildLists"

      counter = 0
      scope.find_each do |bl|
          bl.destroy && (counter += 1)
      end

      say "[#{Time.zone.now}] #{counter} outdated BuildLists have been removed"
      say "[#{Time.zone.now}] Outdated BuildLists were successfully removed"
    end

  end

  namespace :packages do
    # TODO Maybe do it in migration, because it's just a single query?
    desc 'Actualize packages for all platforms'
    task actualize: :environment do

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
      } ).update_all(actual: true)
      say "'Actual' setted to #{packages} packages"
    end
  end
end

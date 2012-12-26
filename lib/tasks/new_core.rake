namespace :new_core do
  desc 'Sets bs_id field for all BuildList which use new_core'
  task :update_bs_id => :environment do
    say "[#{Time.zone.now}] Starting to update bs_id..."

    BuildList.select(:id).
      where(:new_core => true, :bs_id => nil).
      find_in_batches(:batch_size => 500) do | bls |

      puts "[#{Time.zone.now}] - where build_lists.id from #{bls.first.id} to #{bls.last.id}"
      BuildList.where(:id => bls.map(&:id), :bs_id => nil).
        update_all("bs_id = id")
    end

    say "[#{Time.zone.now}] done"
  end
end
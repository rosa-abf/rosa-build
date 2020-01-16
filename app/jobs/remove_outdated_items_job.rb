class RemoveOutdatedItemsJob
  def self.perform
    log_file = Rails.root.join("log", "remove_outdated.log").to_s
    counter_bl = 0
    BuildList.outdated.find_each(batch_size: 100) do |bl|
      bl.destroy && (counter_bl += 1) if bl.id != bl.last_published.first.try(:id)
    end
    counter_mb = 0
    MassBuild.outdated.find_each do |mb|
      mb.destroy && (counter_mb += 1) if mb.build_lists.count == 0
    end
    User.find_each do |user|
      user.activity_feeds.outdated.destroy_all
    end
    counter_pbl = ProductBuildList.outdated.count
    ProductBuildList.outdated.destroy_all
    File.open(log_file, "w") do |f|
      f.puts "Build Lists deleted: #{counter_bl}"
      f.puts "Mass Builds deleted: #{counter_mb}"
      f.puts "Product Build Lists deleted: #{counter_pbl}"
    end
  end
end

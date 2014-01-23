namespace :activity_feeds do
  desc 'Remove outdated activity feeds'
  task clear: :environment do
    say "Removing outdated Activity Feed"
    User.all.each do |user|
      outdated = ActivityFeed.outdated
      say "User #{user.uname} has #{outdated.count} outdated ActivityFeed."
      user.activity_feeds.outdated.destroy_all if outdated.count > 0
    end
    say "Outdated activity feeds was successfully removed."
  end
end

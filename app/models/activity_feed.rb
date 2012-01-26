class ActivityFeed < ActiveRecord::Base
  belongs_to :user

  serialize :data

  def partial
    'activity_feeds/partials/' + self.kind
  end
end

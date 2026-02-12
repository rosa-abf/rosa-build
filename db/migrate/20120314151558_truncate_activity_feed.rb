class TruncateActivityFeed < ActiveRecord::Migration[8.1]
  def up
    ActivityFeed.destroy_all
  end

  def down
  end
end

class AddUserIndexToActivityFeed < ActiveRecord::Migration
  def change
    add_index :activity_feeds, [:user_id, :kind]
  end
end

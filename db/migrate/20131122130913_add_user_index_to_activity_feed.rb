class AddUserIndexToActivityFeed < ActiveRecord::Migration[8.1]
  def change
    add_index :activity_feeds, [:user_id, :kind]
  end
end

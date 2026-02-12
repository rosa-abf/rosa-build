class CreateActivityFeeds < ActiveRecord::Migration[8.1]
  def self.up
    create_table :activity_feeds, if_not_exists: true do |t|
      t.integer :user_id, null: false
      t.string :kind
      t.text :data

      t.timestamps
    end
  end

  def self.down
    drop_table :activity_feeds
  end
end

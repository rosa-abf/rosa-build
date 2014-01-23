class CreateActivityFeeds < ActiveRecord::Migration
  def self.up
    create_table :activity_feeds do |t|
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

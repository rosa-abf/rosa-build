class AddOwnerNameAndCreatorToActivityFeeds < ActiveRecord::Migration
  def up
    add_column :activity_feeds, :project_owner, :string
    add_column :activity_feeds, :project_name, :string
    add_column :activity_feeds, :creator_id, :integer

    add_index :activity_feeds, :project_owner
    add_index :activity_feeds, :project_name
    add_index :activity_feeds, :creator_id

    ActivityFeed.reset_column_information
    ActivityFeed.find_each do |feed|
      feed.project_owner        = feed.data[:project_owner]
      feed.project_name         = feed.data[:project_name]
      feed.creator_id           = feed.data[:user_id]
      feed.data[:creator_name]  = feed.data[:user_name]
      feed.data[:creator_email] = feed.data[:user_email]
      feed.data[:project_owner] = nil
      feed.data[:project_name]  = nil
      feed.data[:user_id]       = nil
      feed.data[:user_name]     = nil
      feed.data[:user_email]    = nil
      feed.save
    end
  end

  def down
    remove_column :activity_feeds, :project_owner
    remove_column :activity_feeds, :project_name
    remove_column :activity_feeds, :creator_id
  end
end

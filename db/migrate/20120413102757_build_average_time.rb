class BuildAverageTime < ActiveRecord::Migration
  def change
  	add_column :projects, :average_build_time, :integer, null: false, default: 0
    add_column :projects, :build_count, :integer, null: false, default: 0
  end

  ActivityFeed.where(kind: 'build_list_notification').destroy_all

end

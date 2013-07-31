class DropAverageBuildTimeAndBuildCountFromProject < ActiveRecord::Migration
  def up
    remove_column :projects, :average_build_time
    remove_column :projects, :build_count
  end

  def down
    add_column :projects, :average_build_time, :integer, :null => false, :default => 0
    add_column :projects, :build_count, :integer, :null => false, :default => 0
  end
end

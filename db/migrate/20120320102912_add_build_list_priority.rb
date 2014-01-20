class AddBuildListPriority < ActiveRecord::Migration
  def self.up
    add_column :build_lists, :priority, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :build_lists, :priority
  end
end

class AddIsCircleToBuildLists < ActiveRecord::Migration
  def self.up
    add_column :build_lists, :is_circle, :boolean, default: false
  end

  def self.down
    remove_column :build_lists, :is_circle
  end
end

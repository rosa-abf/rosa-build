class RemovePlatformIdFromProjects < ActiveRecord::Migration
  def self.up
    remove_column :projects, :platform_id
  end

  def self.down
    add_column :projects, :platform_id, :integer, :null => false
  end
end

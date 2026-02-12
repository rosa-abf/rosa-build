class RemovePlatformIdFromProjects < ActiveRecord::Migration[8.1]
  def self.up
    remove_column :projects, :platform_id
  end

  def self.down
    add_column :projects, :platform_id, :integer, null: false
  end
end

class RemoveRepositoryIdFromProject < ActiveRecord::Migration
  def self.up
    remove_column :projects, :repository_id
  end

  def self.down
    add_column :projects, :repository_id, :integer, null: false
  end
end

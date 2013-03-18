class AddRepositoryIdToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :repository_id, :integer, :null => false
  end

  def self.down
    remove_column :projects, :repository_id
  end
end

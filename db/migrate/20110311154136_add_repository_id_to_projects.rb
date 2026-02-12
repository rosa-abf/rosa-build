class AddRepositoryIdToProjects < ActiveRecord::Migration[8.1]
  def self.up
    add_column :projects, :repository_id, :integer, null: false
  end

  def self.down
    remove_column :projects, :repository_id
  end
end

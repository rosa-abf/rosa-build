class AddIndexes < ActiveRecord::Migration
  def change
    add_index :project_to_repositories, [:repository_id, :project_id], unique: true
    add_index :repositories, :platform_id
  end
end

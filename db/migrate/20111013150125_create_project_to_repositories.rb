class CreateProjectToRepositories < ActiveRecord::Migration
  def self.up
    create_table :project_to_repositories do |t|
      t.integer :id
      t.integer :project_id
      t.integer :repository_id

      t.timestamps
    end
  end

  def self.down
    drop_table :project_to_repositories
  end
end

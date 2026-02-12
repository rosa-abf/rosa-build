class CreateProjectToRepositories < ActiveRecord::Migration[8.1]
  def change
    create_table :project_to_repositories do |t|
      t.integer :project_id
      t.integer :repository_id

      t.timestamps
    end
  end
end

class CreateProjectImports < ActiveRecord::Migration[8.1]
  def self.up
    create_table :project_imports do |t|
      t.references :project
      t.string :name
      t.string :version
      t.datetime :file_mtime

      t.timestamps
    end
  end

  def self.down
    drop_table :project_imports
  end
end

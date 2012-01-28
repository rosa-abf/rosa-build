class AddIndexForProjectsName < ActiveRecord::Migration
  def self.up
    add_index :projects, :name
    add_index :project_imports, :name
  end

  def self.down
    remove_index :projects, :name
    remove_index :project_imports, :name
  end
end

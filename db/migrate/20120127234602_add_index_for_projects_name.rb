class AddIndexForProjectsName < ActiveRecord::Migration
  def self.up
    add_index :projects, [:name, :owner_id, :owner_type], :unique => true, :case_sensitive => false
    add_index :project_imports, :name, :unique => true, :case_sensitive => false
  end

  def self.down
    remove_index :projects, [:name, :owner_id, :owner_type]
    remove_index :project_imports, :name
  end
end

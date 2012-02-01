class AddPlatformReferenceToProjectImports < ActiveRecord::Migration
  def self.up
    add_column :project_imports, :platform_id, :integer
    remove_index :project_imports, :name
    add_index :project_imports, [:name, :platform_id], :unique => true, :case_sensitive => false
  end

  def self.down
    remove_index :project_imports, [:name, :platform_id]
    add_index :project_imports, :name, :unique => true, :case_sensitive => false
    remove_column :project_imports, :platform_id
  end
end

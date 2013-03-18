class AddNewFieldsToBuildLists < ActiveRecord::Migration
  def self.up
    add_column :build_lists, :build_requires, :boolean
    add_column :build_lists, :update_type, :string
    add_column :build_lists, :bpl_id, :integer
    add_column :build_lists, :pl_id, :integer
    rename_column :build_lists, :branch_name, :project_version
  end

  def self.down
    rename_column :build_lists, :project_version, :branch_name
    remove_column :build_lists, :bpl_id
    remove_column :build_lists, :pl_id
    remove_column :build_lists, :update_type
    remove_column :build_lists, :build_requires
  end
end

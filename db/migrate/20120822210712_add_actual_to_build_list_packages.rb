class AddActualToBuildListPackages < ActiveRecord::Migration
  def self.up
    add_column :build_list_packages, :actual, :boolean, :default => false
    add_index :build_list_packages, [:actual, :platform_id], :name => :actual_platform_packages
    add_index :build_list, [:project_id, :save_to_repository_id, :build_for_platform_id, :arch_id]
  end

  def self.down
    remove_column :build_list_packages, :actual
    remove_index :build_list_packages, [:actual, :platform_id], :name => :actual_platform_packages
    remove_index :build_list, [:project_id, :save_to_repository_id, :build_for_platform_id, :arch_id]
  end
end

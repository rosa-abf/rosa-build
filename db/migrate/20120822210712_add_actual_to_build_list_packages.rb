class AddActualToBuildListPackages < ActiveRecord::Migration
  def self.up
    add_column :build_list_packages, :actual, :boolean, default: false
    add_index :build_list_packages, [:actual, :platform_id]
    add_index :build_lists, [:project_id, :save_to_repository_id, :build_for_platform_id, :arch_id],
              name: :maintainer_search_index
  end

  def self.down
    remove_index :build_list_packages, [:actual, :platform_id]
    remove_column :build_list_packages, :actual
    remove_index :build_lists, name: :maintainer_search_index
  end
end

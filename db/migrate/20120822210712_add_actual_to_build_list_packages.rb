class AddActualToBuildListPackages < ActiveRecord::Migration
  def self.up
    add_column :build_list_packages, :actual, :boolean, :default => false
    add_index :build_list_packages, [:actual, :platform_id], :name => :actual_platform_packages
  end

  def self.down
    remove_column :build_list_packages, :actual
  end
end

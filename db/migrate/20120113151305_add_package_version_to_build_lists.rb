class AddPackageVersionToBuildLists < ActiveRecord::Migration
  def self.up
    add_column :build_lists, :package_version, :string
  end

  def self.down
    remove_column :build_lists, :package_version
  end
end

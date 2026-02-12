class AddPackageVersionToBuildLists < ActiveRecord::Migration[8.1]
  def self.up
    add_column :build_lists, :package_version, :string
  end

  def self.down
    remove_column :build_lists, :package_version
  end
end

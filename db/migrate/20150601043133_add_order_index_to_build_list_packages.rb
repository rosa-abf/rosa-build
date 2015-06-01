class AddOrderIndexToBuildListPackages < ActiveRecord::Migration
  def up
    add_index :build_list_packages, name: :build_list_packages_ordering,
              expression: "lower(build_list_packages.name) ASC, length(build_list_packages.name) ASC"
  end

  def down
    remove_index :build_list_packages, name: :build_list_packages_ordering, if_exists: true
  end
end

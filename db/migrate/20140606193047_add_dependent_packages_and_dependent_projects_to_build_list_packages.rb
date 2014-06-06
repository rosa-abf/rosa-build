class AddDependentPackagesAndDependentProjectsToBuildListPackages < ActiveRecord::Migration
  def change
    add_column :build_list_packages, :dependent_packages, :text
    add_column :build_list_packages, :dependent_projects, :text
  end
end

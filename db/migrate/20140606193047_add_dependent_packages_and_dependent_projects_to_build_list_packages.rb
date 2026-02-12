class AddDependentPackagesAndDependentProjectsToBuildListPackages < ActiveRecord::Migration[8.1]
  def change
    add_column :build_list_packages, :dependent_packages, :text
    add_column :build_list_packages, :dependent_projects, :text
  end
end

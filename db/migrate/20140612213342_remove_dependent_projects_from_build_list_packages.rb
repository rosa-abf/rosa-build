class RemoveDependentProjectsFromBuildListPackages < ActiveRecord::Migration[8.1]
  def up
    remove_column :build_list_packages, :dependent_projects
  end

  def down
    add_column :build_list_packages, :dependent_projects, :text
  end
end

class RemoveDependentProjectsFromBuildListPackages < ActiveRecord::Migration
  def up
    remove_column :build_list_packages, :dependent_projects
  end

  def down
    add_column :build_list_packages, :dependent_projects, :text
  end
end

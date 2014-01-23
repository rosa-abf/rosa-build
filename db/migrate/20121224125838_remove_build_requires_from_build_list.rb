class RemoveBuildRequiresFromBuildList < ActiveRecord::Migration
  def up
    remove_column :build_lists, :build_requires
  end

  def down
    add_column :build_lists, :build_requires, :boolean, default: false
  end
end

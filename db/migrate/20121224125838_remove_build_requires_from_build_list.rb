class RemoveBuildRequiresFromBuildList < ActiveRecord::Migration[8.1]
  def up
    remove_column :build_lists, :build_requires
  end

  def down
    add_column :build_lists, :build_requires, :boolean, default: false
  end
end

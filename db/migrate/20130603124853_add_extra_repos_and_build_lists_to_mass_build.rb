class AddExtraReposAndBuildListsToMassBuild < ActiveRecord::Migration
  class MassBuild < ActiveRecord::Base
  end

  def up
    add_column    :mass_builds, :save_to_platform_id, :integer
    MassBuild.update_all('save_to_platform_id = platform_id')
    change_column :mass_builds, :save_to_platform_id, :integer, :null => false
    change_column :mass_builds, :platform_id, :integer, :null => false
    rename_column :mass_builds, :platform_id, :build_for_platform_id
    add_column    :mass_builds, :extra_repositories,  :text
    add_column    :mass_builds, :extra_build_lists,   :text
  end

  def down
    remove_column :mass_builds, :extra_repositories
    remove_column :mass_builds, :extra_build_lists
    remove_column :mass_builds, :save_to_platform_id
    rename_column :mass_builds, :build_for_platform_id, :platform_id
  end

end

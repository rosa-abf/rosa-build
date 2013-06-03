class AddSaveToPlatformToMassBuild < ActiveRecord::Migration
  class MassBuild < ActiveRecord::Base
  end

  def up
    add_column    :mass_builds, :save_to_platform_id, :integer
    MassBuild.update_all('save_to_platform_id = platform_id')
    change_column :mass_builds, :save_to_platform_id, :integer, :null => false
    change_column :mass_builds, :platform_id, :integer, :null => false
    rename_column :mass_builds, :platform_id, :build_for_platform_id
    add_column    :mass_builds, :use_save_to_repository, :boolean
  end

  def down
    remove_column :mass_builds, :save_to_platform_id
    remove_column :mass_builds, :use_save_to_repository
    rename_column :mass_builds, :build_for_platform_id, :platform_id
  end

end

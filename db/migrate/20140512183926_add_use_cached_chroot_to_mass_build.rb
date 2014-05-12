class AddUseCachedChrootToMassBuild < ActiveRecord::Migration
  def up
    # Make existing mass_builds 'false', but default to 'true' in the future.
    add_column    :mass_builds, :use_cached_chroot, :boolean, null: false, default: false
    change_column :mass_builds, :use_cached_chroot, :boolean, null: false, default: true
  end

  def down
    remove_column :mass_builds, :use_cached_chroot
  end

end

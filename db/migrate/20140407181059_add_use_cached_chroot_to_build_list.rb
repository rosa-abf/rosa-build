class AddUseCachedChrootToBuildList < ActiveRecord::Migration
  def change
    # Make existing build_lists 'false', but default to 'true' in the future.
    add_column    :build_lists, :use_cached_chroot, :boolean, null: false, default: false
    change_column :build_lists, :use_cached_chroot, :boolean, null: false, default: true
  end

  def down
    remove_column :build_lists, :use_cached_chroot
  end
end

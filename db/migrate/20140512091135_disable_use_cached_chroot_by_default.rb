class DisableUseCachedChrootByDefault < ActiveRecord::Migration
  def up
    change_column :build_lists, :use_cached_chroot, :boolean, null: false, default: false
  end

  def down
    change_column :build_lists, :use_cached_chroot, :boolean, null: false, default: true
  end
end

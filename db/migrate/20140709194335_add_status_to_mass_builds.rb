class AddStatusToMassBuilds < ActiveRecord::Migration

  def up
    # Sets SUCCESS for all current builds
    add_column :mass_builds, :status, :integer, null: false, default: 0 # SUCCESS
    # Sets BUILD_PENDING for all new builds
    change_column :mass_builds, :status, :integer, null: false, default: 2000 # BUILD_PENDING
  end

  def down
    remove_column :mass_builds, :status
  end
end

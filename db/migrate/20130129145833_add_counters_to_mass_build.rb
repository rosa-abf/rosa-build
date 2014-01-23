class AddCountersToMassBuild < ActiveRecord::Migration
  def up
    add_column :mass_builds, :success_count, :integer, default: 0, null: false
    add_column :mass_builds, :build_canceled_count, :integer, default: 0, null: false
    change_column :mass_builds, :new_core, :boolean, default: true
  end

  def down
    remove_column :mass_builds, :success_count
    remove_column :mass_builds, :build_canceled_count
    change_column :mass_builds, :new_core, :boolean, default: false
  end
end

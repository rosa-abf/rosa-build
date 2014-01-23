class AddNewCoreToMassBuild < ActiveRecord::Migration
  def change
    add_column :mass_builds, :new_core, :boolean, default: false
  end
end

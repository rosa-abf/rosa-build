class AddNewCoreToMassBuild < ActiveRecord::Migration[8.1]
  def change
    add_column :mass_builds, :new_core, :boolean, default: false
  end
end

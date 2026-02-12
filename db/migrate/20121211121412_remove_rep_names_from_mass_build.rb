class RemoveRepNamesFromMassBuild < ActiveRecord::Migration[8.1]
  def change
    remove_column :mass_builds, :rep_names
  end
end

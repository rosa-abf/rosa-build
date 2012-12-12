class RemoveRepNamesFromMassBuild < ActiveRecord::Migration
  def change
    remove_column :mass_builds, :rep_names
  end
end

class AddIncreaseReleaseTagToMassBuild < ActiveRecord::Migration
  def change
    add_column :mass_builds, :increase_release_tag, :boolean, :default => false, :null => false
  end
end

class AddIncreaseReleaseTagToMassBuild < ActiveRecord::Migration[8.1]
  def change
    add_column :mass_builds, :increase_release_tag, :boolean, default: false, null: false
  end
end

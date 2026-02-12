class AddExtraMassBuildsToMassBuilds < ActiveRecord::Migration[8.1]
  def change
    add_column :mass_builds, :extra_mass_builds, :text
  end
end

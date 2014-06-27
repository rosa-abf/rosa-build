class AddExtraMassBuildsToMassBuilds < ActiveRecord::Migration
  def change
    add_column :mass_builds, :extra_mass_builds, :text
  end
end

class AddRepNamesToMassBuilds < ActiveRecord::Migration
  def change
    add_column :mass_builds, :rep_names, :string
  end
end

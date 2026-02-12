class AddRepNamesToMassBuilds < ActiveRecord::Migration[8.1]
  def change
    add_column :mass_builds, :rep_names, :string
  end
end

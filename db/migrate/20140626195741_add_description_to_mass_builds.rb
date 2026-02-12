class AddDescriptionToMassBuilds < ActiveRecord::Migration[8.1]
  def change
    add_column :mass_builds, :description, :string
  end
end

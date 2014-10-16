class AddDescriptionToMassBuilds < ActiveRecord::Migration
  def change
    add_column :mass_builds, :description, :string
  end
end

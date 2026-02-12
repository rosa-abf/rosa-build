class AddExternalNodesToMassBuilds < ActiveRecord::Migration[8.1]
  def change
    add_column :mass_builds, :external_nodes, :string
  end
end

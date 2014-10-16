class AddExternalNodesToMassBuilds < ActiveRecord::Migration
  def change
    add_column :mass_builds, :external_nodes, :string
  end
end

class AddMassBuildIndexToBuildList < ActiveRecord::Migration[8.1]
  def change
    add_index :build_lists, [:mass_build_id, :status]
  end
end

class AddMassBuildIndexToBuildList < ActiveRecord::Migration
  def change
    add_index :build_lists, [:mass_build_id, :status]
  end
end

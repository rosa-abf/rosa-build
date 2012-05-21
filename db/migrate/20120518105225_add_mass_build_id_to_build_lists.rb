class AddMassBuildIdToBuildLists < ActiveRecord::Migration
  def change
    add_column :build_lists, :mass_build_id, :integer
  end
end

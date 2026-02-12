class AddMassBuildIdToBuildLists < ActiveRecord::Migration[8.1]
  def change
    add_column :build_lists, :mass_build_id, :integer
  end
end

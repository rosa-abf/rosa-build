class DropBsIdFromBuildLists < ActiveRecord::Migration
  def change
    remove_index :build_lists, :bs_id
    remove_column :build_lists, :bs_id
  end

end

class RenameExtraContainersIntoExtraBuildLists < ActiveRecord::Migration
  def change
    rename_column :build_lists, :extra_containers, :extra_build_lists
  end
end

class RenameExtraContainersIntoExtraBuildLists < ActiveRecord::Migration[8.1]
  def change
    rename_column :build_lists, :extra_containers, :extra_build_lists
  end
end

class DropUseSaveToRepositoryFromBuildLists < ActiveRecord::Migration
  def up
    remove_column :build_lists, :use_save_to_repository
  end

  def down
    add_column :build_lists, :use_save_to_repository, :boolean, default: true
  end
end

class DropBsIdFromBuildLists < ActiveRecord::Migration

  class BuildList < ActiveRecord::Base
  end

  def up
    remove_index  :build_lists, :bs_id
    remove_column :build_lists, :bs_id
  end

  def down
    add_column  :build_lists, :bs_id, :integer
    add_index   :build_lists, :bs_id, :unique => true
    BuildList.update_all('bs_id = id')
  end

end

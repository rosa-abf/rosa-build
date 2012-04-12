class RemoveUnusedFields < ActiveRecord::Migration
  def up
    remove_column :build_lists, :started_at
    remove_column :build_lists, :finished_at
  end

  def down
  end
end

class RemoveOldTables2 < ActiveRecord::Migration
  def change
    drop_table :key_pairs_backup
  end
end

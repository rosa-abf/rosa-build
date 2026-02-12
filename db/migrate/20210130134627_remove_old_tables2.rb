class RemoveOldTables2 < ActiveRecord::Migration[8.1]
  def change
    drop_table :key_pairs_backup
  end
end

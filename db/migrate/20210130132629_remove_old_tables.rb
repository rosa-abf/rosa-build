class RemoveOldTables < ActiveRecord::Migration
  def change
    drop_table :node_instructions
    drop_table :build_scripts
    drop_table :register_requests
    drop_table :authentications
  end
end

class CreateRepositoryStatuses < ActiveRecord::Migration
  def change
    create_table :repository_statuses do |t|
      t.integer :repository_id, :null => false
      t.integer :platform_id, :null => false
      t.integer :status
      t.datetime :last_regenerated_at
      t.integer :last_regenerated_status

      t.timestamps
    end
    add_index :repository_statuses, [:repository_id, :platform_id], :unique => true
  end
end

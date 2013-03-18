class CreatePermissions < ActiveRecord::Migration
  def self.up
    create_table :permissions do |t|
      t.integer :id
      t.integer :right_id
      t.integer :role_id

      t.timestamps
    end
  end

  def self.down
    drop_table :permissions
  end
end

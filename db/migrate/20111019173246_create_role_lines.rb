class CreateRoleLines < ActiveRecord::Migration
  def self.up
    create_table :role_lines do |t|
      t.integer :role_id
      t.integer :relation_id
      t.timestamps
    end
  end

  def self.down
    drop_table :role_lines
  end
end

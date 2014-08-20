class CreatePermissions < ActiveRecord::Migration
  def change
    create_table :permissions do |t|
      t.integer :right_id,  references: nil
      t.integer :role_id,   references: nil

      t.timestamps
    end
  end
end

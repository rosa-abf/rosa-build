class CreatePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :permissions do |t|
      t.integer :right_id #,  references: nil
      t.integer :role_id #,   references: nil

      t.timestamps
    end
  end
end

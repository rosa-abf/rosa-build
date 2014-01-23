class CreateSshKeys < ActiveRecord::Migration
  def change
    create_table :ssh_keys do |t|
      t.string :name
      t.text :key, null: false
      t.string :fingerprint, null: false
      t.integer :user_id, null: false

      t.timestamps
    end

    add_index :ssh_keys, :fingerprint, unique: true
    add_index :ssh_keys, :user_id
  end
end

class CreateRegisterRequests < ActiveRecord::Migration
  def self.up
    create_table :register_requests do |t|
      t.string :name
      t.string :email
      t.string :token
      t.boolean :approved, default: false
      t.boolean :rejected, default: false

      t.timestamps
    end
    add_index :register_requests, [:email], unique: true, case_sensitive: false
    add_index :register_requests, [:token], unique: true, case_sensitive: false
  end

  def self.down
    remove_index :register_requests, [:email]
    remove_index :register_requests, [:token]
    drop_table :register_requests
  end
end

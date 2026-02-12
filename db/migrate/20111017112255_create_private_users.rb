class CreatePrivateUsers < ActiveRecord::Migration[8.1]
  def self.up
    create_table :private_users do |t|
      t.integer :platform_id
      t.string :login
      t.string :password
      t.timestamps
    end
  end

  def self.down
    drop_table :private_users
  end
end

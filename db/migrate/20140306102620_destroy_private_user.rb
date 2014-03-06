class DestroyPrivateUser < ActiveRecord::Migration
  def self.up
    drop_table :private_users
  end

  def self.down
    create_table :private_users do |t|
      t.integer :platform_id
      t.string :login
      t.string :password
      t.integer :user_id
      t.timestamps
    end
  end
end

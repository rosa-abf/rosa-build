class AddUserIdToPrivateUsers < ActiveRecord::Migration
  def self.up
    add_column :private_users, :user_id, :integer
  end

  def self.down
    remove_column :private_users, :user_id
  end
end

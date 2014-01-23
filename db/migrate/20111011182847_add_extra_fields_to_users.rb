class AddExtraFieldsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :nickname, :string
    add_column :users, :ssh_key, :text
    add_index :users, :nickname, unique: true
    User.all.each {|u| User.where(id: u.id).update_all(nickname: u.email.split('@').first)}
  end

  def self.down
    remove_column :users, :ssh_key
    remove_column :users, :nickname
  end
end

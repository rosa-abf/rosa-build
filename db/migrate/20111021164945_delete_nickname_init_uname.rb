class DeleteNicknameInitUname < ActiveRecord::Migration
  def self.up
    remove_column :users, :nickname
    add_index :users, :uname, unique: true
    User.all.each {|u| User.where(id: u.id).update_all(uname: u.email.split('@').first.gsub(/[^a-zA-Z0-9_]/, '_'))}
  end

  def self.down
    add_column :users, :nickname, :string
    remove_index :users, :uname
    User.all.each {|u| User.where(id: u.id).update_all(nickname: u.email.split('@').first.gsub(/[^a-zA-Z0-9_]/, '_'))}
  end
end

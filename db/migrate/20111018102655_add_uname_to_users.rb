class AddUnameToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :uname, :string
  end

  def self.down
    remove_column :users, :uname
  end
end

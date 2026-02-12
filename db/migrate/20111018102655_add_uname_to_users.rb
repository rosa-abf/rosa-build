class AddUnameToUsers < ActiveRecord::Migration[8.1]
  def self.up
    add_column :users, :uname, :string
  end

  def self.down
    remove_column :users, :uname
  end
end

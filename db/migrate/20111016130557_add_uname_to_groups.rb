class AddUnameToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :uname, :string
  end

  def self.down
    remove_column :groups, :uname
  end
end

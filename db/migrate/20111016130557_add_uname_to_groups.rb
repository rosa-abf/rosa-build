class AddUnameToGroups < ActiveRecord::Migration[8.1]
  def self.up
    add_column :groups, :uname, :string
  end

  def self.down
    remove_column :groups, :uname
  end
end

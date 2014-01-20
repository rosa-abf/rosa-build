class AddUnixnameToRepositories < ActiveRecord::Migration
  def self.up
    add_column :repositories, :unixname, :string, :null => false
  end

  def self.down
    remove_column :repositories, :unixname
  end
end

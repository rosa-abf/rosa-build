class AddUnixnameToRepositories < ActiveRecord::Migration[8.1]
  def self.up
    add_column :repositories, :unixname, :string, null: false
  end

  def self.down
    remove_column :repositories, :unixname
  end
end

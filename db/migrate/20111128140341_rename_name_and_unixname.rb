class RenameNameAndUnixname < ActiveRecord::Migration
  def self.up
  	remove_column :projects, :name
  	rename_column :projects, :unixname, :name
  	rename_column :platforms, :name, :description
  	rename_column :platforms, :unixname, :name
  	rename_column :repositories, :name, :description
  	rename_column :repositories, :unixname, :name
  end

  def self.down
  	add_column :projects, :name, :string
  	rename_column :projects, :name, :unixname
  	rename_column :platforms, :description, :name
  	rename_column :platforms, :name, :unixname
  	rename_column :repositories, :description, :name
  	rename_column :repositories, :name, :unixname
  end
end

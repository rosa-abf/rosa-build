class AddNameToBuildLists < ActiveRecord::Migration
  def self.up
    add_column :build_lists, :name, :string
  end

  def self.down
    remove_column :build_lists, :name
  end
end

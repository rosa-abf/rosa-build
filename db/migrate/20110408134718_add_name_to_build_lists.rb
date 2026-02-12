class AddNameToBuildLists < ActiveRecord::Migration[8.1]
  def self.up
    add_column :build_lists, :name, :string
  end

  def self.down
    remove_column :build_lists, :name
  end
end

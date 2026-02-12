class AddUserIdToBuildLists < ActiveRecord::Migration[8.1]
  def self.up
    add_column :build_lists, :user_id, :integer
  end

  def self.down
    remove_column :build_lists, :user_id
  end
end

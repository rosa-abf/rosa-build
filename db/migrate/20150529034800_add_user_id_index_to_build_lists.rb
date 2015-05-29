class AddUserIdIndexToBuildLists < ActiveRecord::Migration
  def change
    add_index :build_lists, :user_id
  end
end

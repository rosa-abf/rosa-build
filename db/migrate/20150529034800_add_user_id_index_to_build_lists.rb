class AddUserIdIndexToBuildLists < ActiveRecord::Migration[8.1]
  def change
    add_index :build_lists, :user_id
  end
end

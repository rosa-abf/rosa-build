class AddUserToProductBuildList < ActiveRecord::Migration[8.1]
  def change
    add_column :product_build_lists, :user_id, :integer
  end
end

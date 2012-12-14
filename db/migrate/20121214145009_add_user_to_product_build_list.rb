class AddUserToProductBuildList < ActiveRecord::Migration
  def change
    add_column :product_build_lists, :user_id, :integer
  end
end

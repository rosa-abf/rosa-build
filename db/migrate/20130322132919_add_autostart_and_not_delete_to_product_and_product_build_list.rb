class AddAutostartAndNotDeleteToProductAndProductBuildList < ActiveRecord::Migration
  def change
    add_column :products, :autostart, :integer, :default => nil
    add_column :product_build_lists, :not_delete, :boolean, :default => false
  end
end

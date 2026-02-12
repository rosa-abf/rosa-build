class ChangeLimitsOnIsoBuilds < ActiveRecord::Migration[8.1]
  def change
    change_column :product_build_lists, :params, :text
    change_column :products, :params, :text
  end
end

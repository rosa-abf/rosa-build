class ChangeLimitsOnIsoBuilds < ActiveRecord::Migration
  def change
    change_column :product_build_lists, :params, :text
    change_column :products, :params, :text
  end
end

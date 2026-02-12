class AutostartIsoBuildOnRegularBasis < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :autostart_status, :integer, default: nil
    add_column :product_build_lists, :not_delete, :boolean, default: false
    add_column :product_build_lists, :autostarted, :boolean, default: false
  end
end

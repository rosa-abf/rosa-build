class RemoveDefaultStatusFromProductBuildList < ActiveRecord::Migration[8.1]
  def change
    change_column :product_build_lists, :status, :integer, default: nil
  end
end

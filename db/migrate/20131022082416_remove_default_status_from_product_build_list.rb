class RemoveDefaultStatusFromProductBuildList < ActiveRecord::Migration
  def change
    change_column :product_build_lists, :status, :integer, :default => nil
  end
end

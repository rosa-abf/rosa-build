class RemoveProductNotifiedAt < ActiveRecord::Migration[8.1]
  def up
  	remove_column :product_build_lists, :notified_at
  end

  def down
  	add_column :product_build_lists, :notified_at, :datetime
  end
end

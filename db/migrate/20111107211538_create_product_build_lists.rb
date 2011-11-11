class CreateProductBuildLists < ActiveRecord::Migration
  def self.up
    create_table :product_build_lists do |t|
      t.references :product
      t.integer :status, :null => false, :default => ProductBuildList::BUILD_STARTED
      t.datetime :notified_at

      t.timestamps
    end
    add_index :product_build_lists, :product_id
  end

  def self.down
    drop_table :product_build_lists
  end
end

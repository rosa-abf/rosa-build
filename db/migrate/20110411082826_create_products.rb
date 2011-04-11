class CreateProducts < ActiveRecord::Migration
  def self.up
    create_table :products do |t|
      t.string :name, :null => false
      t.integer :platform_id, :null => false
      t.integer :build_status, :default => 2, :null => false ### NOTE :default => 2 comes from Product::NEVER_BUILT status which we unable to use here
      t.string :build_path

      t.timestamps
    end
  end

  def self.down
    drop_table :products
  end
end

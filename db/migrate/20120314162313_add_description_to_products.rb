class AddDescriptionToProducts < ActiveRecord::Migration[8.1]
  def self.up
    add_column :products, :description, :text
    execute "UPDATE products SET description = name"
  end

  def self.down
    remove_column :products, :description
  end
end

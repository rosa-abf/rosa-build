class AddFieldsToProducts < ActiveRecord::Migration[8.1]
  def self.up
    add_column :products, :build, :text
    add_column :products, :counter, :text
    add_column :products, :ks, :text
    add_column :products, :menu, :text
  end

  def self.down
    remove_column :products, :menu
    remove_column :products, :ks
    remove_column :products, :counter
    remove_column :products, :build
  end
end

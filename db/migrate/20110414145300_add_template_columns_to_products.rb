class AddTemplateColumnsToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :is_template, :boolean, :default => false
    add_column :products, :system_wide, :boolean, :default => false
  end

  def self.down
    remove_column :products, :is_template
    remove_column :products, :system_wide
  end
end

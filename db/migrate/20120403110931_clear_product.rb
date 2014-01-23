class ClearProduct < ActiveRecord::Migration
  def self.up
    remove_column :products, :build_status
    remove_column :products, :build_path
    remove_column :products, :system_wide
  end

  def self.down
    add_column :products, :build_status, :integer, default: 2, null: false
    add_column :products, :build_path, :string
    add_column :products, :system_wide, :boolean, default: false
  end
end

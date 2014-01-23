class PlatformRestruct < ActiveRecord::Migration
  def self.up
    change_table :platforms do |t|
      t.references :owner, polymorphic: true
      t.string :visibility, default: 'open'
      t.string :platform_type, default: 'main'
      t.string :distrib_type
    end
  end

  def self.down
    remove_column :platforms, :visibility
    remove_column :platforms, :owner_id
    remove_column :platforms, :owner_type
    remove_column :platforms, :platform_type
    remove_column :platforms, :distrib_type
  end
end

class AddReleasedToPlatforms < ActiveRecord::Migration
  def self.up
    add_column :platforms, :released, :boolean, :default => false
  end

  def self.down
    remove_column :platforms, :released
  end
end

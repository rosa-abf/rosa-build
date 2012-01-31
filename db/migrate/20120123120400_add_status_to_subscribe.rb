class AddStatusToSubscribe < ActiveRecord::Migration
  def self.up
    add_column :subscribes, :status, :boolean, :default => true
  end

  def self.down
    remove_column :subscribes, :status
  end
end

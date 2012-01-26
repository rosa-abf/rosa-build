class AddStatusToSubscribe < ActiveRecord::Migration
  def self.up
    add_column :subscribes, :status, :integer, :default => 1
  end

  def self.down
    remove_column :subscribes, :status
  end
end

class ChangeStatusSubscribes < ActiveRecord::Migration
  def self.up
    remove_column :subscribes, :status
    add_column :subscribes, :status, :boolean, :default => true
  end

  def self.down
    remove_column :subscribes, :status
    add_column :subscribes, :status, :integer, :default => 1
  end
end

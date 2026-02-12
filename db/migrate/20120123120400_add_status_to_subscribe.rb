class AddStatusToSubscribe < ActiveRecord::Migration[8.1]
  def self.up
    add_column :subscribes, :status, :boolean, default: true
  end

  def self.down
    remove_column :subscribes, :status
  end
end

class AddMoreFieldsToRegisterRequests < ActiveRecord::Migration
  def self.up
    add_column :register_requests, :interest, :string
    add_column :register_requests, :more, :text
  end

  def self.down
    remove_column :register_requests, :interest
    remove_column :register_requests, :more
  end
end

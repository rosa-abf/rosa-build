class AddMoreFieldsToRegisterRequests < ActiveRecord::Migration[8.1]
  def self.up
    add_column :register_requests, :interest, :string
    add_column :register_requests, :more, :text
  end

  def self.down
    remove_column :register_requests, :interest
    remove_column :register_requests, :more
  end
end

class AddAccessToTokenApiToUsers < ActiveRecord::Migration
  def change
    add_column :users, :access_to_token_api, :bool, default: false
  end
end

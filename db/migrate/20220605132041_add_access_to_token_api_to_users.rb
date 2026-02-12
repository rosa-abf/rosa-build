class AddAccessToTokenApiToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :access_to_token_api, :bool, default: false
  end
end

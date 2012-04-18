class AddTokenAuthenticatableToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.token_authenticatable
    end

    add_index :users, :authentication_token

    User.all.each do |user|
      user.ensure_authentication_token!
    end
  end
end

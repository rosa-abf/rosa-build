class UpgradeDevise < ActiveRecord::Migration
  def up
    remove_column :users, :remember_token if User.column_names.include?('remember_token')
    add_column :users, :reset_password_sent_at, :datetime unless User.column_names.include?('reset_password_sent_at')
  end

  def down
    remove_column :users, :reset_password_sent_at if User.column_names.include?('reset_password_sent_at')
    add_column :users, :remember_token, :string unless User.column_names.include?('remember_token')
  end
end

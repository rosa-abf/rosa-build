class AddHideEmailToUsers < ActiveRecord::Migration
  def change
    add_column :users, :hide_email, :boolean, default: true, null: false
  end
end

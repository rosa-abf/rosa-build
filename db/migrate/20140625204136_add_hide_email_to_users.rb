class AddHideEmailToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :hide_email, :boolean, default: true, null: false
  end
end

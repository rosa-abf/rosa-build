class AddEmailLowerToUserEmails < ActiveRecord::Migration
  def self.up
    add_column :user_emails, :email_lower, :string
    remove_index :user_emails, :email

    UserEmail.reset_column_information
    UserEmail.update_all("email_lower = lower(email)")

    change_column :user_emails, :email_lower, :string, :null => false
    add_index :user_emails, :email_lower
  end

  def self.down
    remove_column :user_emails, :email_lower
    add_index :user_emails, :email
    remove_index :user_emails, :email_lower
  end
end

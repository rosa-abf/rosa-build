class CreateUserEmails < ActiveRecord::Migration
  def self.up
    create_table :user_emails do |t|
      t.integer :user_id, :null => false
      t.string :email, :null => false

      t.timestamps
    end

    add_index :user_emails, :user_id
    add_index :user_emails, :email
    UserEmail.reset_column_information
    User.all.each do |u|
      UserEmail.create(:user_id => u.id, :email => u.email)
    end
  end

  def self.down
    drop_table :user_emails
  end
end

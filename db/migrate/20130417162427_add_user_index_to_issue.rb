class AddUserIndexToIssue < ActiveRecord::Migration
  def change
    add_index :issues, :user_id
  end
end

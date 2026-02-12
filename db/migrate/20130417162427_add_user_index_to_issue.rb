class AddUserIndexToIssue < ActiveRecord::Migration[8.1]
  def change
    add_index :issues, :user_id
  end
end

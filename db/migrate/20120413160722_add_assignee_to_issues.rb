class AddAssigneeToIssues < ActiveRecord::Migration
  def up
    rename_column :issues, :user_id, :assignee_id
    rename_column :issues, :creator_id, :user_id
  end

  def down
    rename_column :issues, :user_id, :creator_id
    rename_column :issues, :assignee_id, :user_id
  end
end

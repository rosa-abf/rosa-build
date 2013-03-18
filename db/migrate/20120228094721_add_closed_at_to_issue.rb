class AddClosedAtToIssue < ActiveRecord::Migration
  def change
    add_column :issues, :closed_at, :datetime
  end
end

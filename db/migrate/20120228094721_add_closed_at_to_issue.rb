class AddClosedAtToIssue < ActiveRecord::Migration[8.1]
  def change
    add_column :issues, :closed_at, :datetime
  end
end

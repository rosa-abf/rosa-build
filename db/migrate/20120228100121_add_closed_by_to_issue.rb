class AddClosedByToIssue < ActiveRecord::Migration[8.1]
  def change
    add_column :issues, :closed_by, :integer

  end
end

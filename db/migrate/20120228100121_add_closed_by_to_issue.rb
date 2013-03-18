class AddClosedByToIssue < ActiveRecord::Migration
  def change
    add_column :issues, :closed_by, :integer

  end
end

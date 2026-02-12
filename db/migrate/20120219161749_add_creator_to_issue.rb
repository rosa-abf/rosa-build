class AddCreatorToIssue < ActiveRecord::Migration[8.1]
  def change
    add_column :issues, :creator_id, :integer #, references: nil
  end
end

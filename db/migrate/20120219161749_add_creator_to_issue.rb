class AddCreatorToIssue < ActiveRecord::Migration
  def change
    add_column :issues, :creator_id, :integer, references: nil
  end
end

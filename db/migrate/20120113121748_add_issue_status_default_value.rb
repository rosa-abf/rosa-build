class AddIssueStatusDefaultValue < ActiveRecord::Migration[8.1]
  def self.up
    change_column :issues, :status, :string, default: 'open'
  end

  def self.down
    change_column :issues, :status, :string, null: true
  end
end

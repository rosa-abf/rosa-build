class AddIssueStatusDefaultValue < ActiveRecord::Migration
  def self.up
    change_column :issues, :status, :string, :default => 'open'
  end

  def self.down
    change_column :issues, :status, :string, :null => true
  end
end

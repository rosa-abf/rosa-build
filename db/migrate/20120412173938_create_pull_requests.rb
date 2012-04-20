class CreatePullRequests < ActiveRecord::Migration
  def change
    add_column :issues, :type, :string
    rename_column :issues, :status, :state
    add_column :issues, :data, :text, :null => false, :default => 0
  end
end

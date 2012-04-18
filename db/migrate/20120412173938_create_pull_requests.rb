class CreatePullRequests < ActiveRecord::Migration
  def change
    add_column :issues, :type, :string
    add_column :issues, :state, :string
    add_column :issues, :data, :text, :null => false, :default => 0
  end
end

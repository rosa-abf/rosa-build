class AddAddInfoToComments < ActiveRecord::Migration
  def change
    add_column :comments, :created_from_commit_hash, :decimal, precision: 50, scale: 0
    add_column :comments, :created_from_issue_id, :integer

    add_index :comments, :created_from_issue_id
    add_index :comments, :created_from_commit_hash
  end
end

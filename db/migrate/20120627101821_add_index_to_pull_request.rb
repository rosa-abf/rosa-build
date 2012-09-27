class AddIndexToPullRequest < ActiveRecord::Migration
  def change
    add_index :pull_requests, :base_project_id
    add_index :pull_requests, :head_project_id
    add_index :pull_requests, :issue_id
  end
end

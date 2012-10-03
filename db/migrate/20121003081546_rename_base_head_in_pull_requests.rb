class RenameBaseHeadInPullRequests < ActiveRecord::Migration
  def change
    rename_column :pull_requests, :base_project_id, :to_project_id
    rename_column :pull_requests, :base_ref, :to_ref
    rename_column :pull_requests, :head_project_id, :from_project_id
    rename_column :pull_requests, :head_ref, :from_ref
  end
end

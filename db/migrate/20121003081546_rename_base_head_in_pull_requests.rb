class RenameBaseHeadInPullRequests < ActiveRecord::Migration
  def change
    change_table :pull_requests do |t|
      t.rename :base_project_id, :to_project_id
      t.rename :base_ref, :to_ref
      t.rename :head_project_id, :from_project_id
      t.rename :head_ref, :from_ref
    end
  end
end

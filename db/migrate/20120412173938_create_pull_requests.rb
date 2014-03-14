class CreatePullRequests < ActiveRecord::Migration
  def change
    create_table :pull_requests do |t|
      t.integer :issue_id, null: false
      t.integer :base_project_id, null: false, references: nil
      t.integer :head_project_id, null: false, references: nil
      t.string :base_ref, null: false
      t.string :head_ref, null: false
    end
  end
end

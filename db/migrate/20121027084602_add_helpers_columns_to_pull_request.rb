class AddHelpersColumnsToPullRequest < ActiveRecord::Migration
  def up
    add_column :pull_requests, :from_project_owner_uname, :string
    add_column :pull_requests, :from_project_name, :string
    # includes generate error "undefined method `repo' for nil:NilClass"
    # update not orphan pulls. For other need execute a task project:fix_orphan_pulls
    PullRequest.joins(:from_project).each {|pull| pull.from_project_name = pull.from_project.name}
  end

  def down
    remove_column :pull_requests, :from_project_owner_uname
    remove_column :pull_requests, :from_project_name
  end
end

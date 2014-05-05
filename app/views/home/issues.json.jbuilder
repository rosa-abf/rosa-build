json.all_count      @all_issues.not_closed_or_merged.count
json.assigned_count @assigned_issues.not_closed_or_merged.count
json.created_count  @created_issues.not_closed_or_merged.count

json.content do
  json.array!(@issues) do |issue|
    json.serial_id issue.serial_id
    json.project_name issue.project.name
    json.title issue.title
    json.issue_url polymorphic_path [@project || issue.project, issue.pull_request ? issue.pull_request : issue]
    json.updated_at issue.updated_at
    json.created_at issue.created_at
    json.user do
      json.link user_path(issue.user) if issue.user
      json.uname issue.user.uname  if issue.user
    end
    json.assignee do
      json.link user_path(issue.assignee) if issue.assignee
      json.image avatar_url(issue.assignee, :micro) if issue.assignee
      json.fullname issue.assignee.fullname if issue.assignee
    end
  end
end
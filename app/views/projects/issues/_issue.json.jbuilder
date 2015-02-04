json.(issue, :serial_id, :title)
json.path project_issue_path(issue.project, issue)

json.labels do
  json.array!(issue.labels) do |label|
    json.name  label.name
    json.color "##{label.color}"
  end
end

json.user do
  json.uname issue.user.uname
  json.path user_path(issue.user)
end

json.updated_at     issue.updated_at
json.updated_at_utc issue.updated_at.strftime('%Y-%m-%d %H:%M:%S UTC')

json.created_at     issue.created_at
json.created_at_utc issue.created_at.strftime('%Y-%m-%d %H:%M:%S UTC')

if issue.assignee
  json.assignee do
    json.path     user_path(issue.assignee)
    json.image    avatar_url(issue.assignee, :micro)
    json.fullname issue.assignee.fullname
  end
else
  json.assignee do
  end
end

json.comments_count issue.comments.where(automatic: false).count

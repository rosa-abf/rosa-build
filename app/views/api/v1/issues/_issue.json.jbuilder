json.number issue.serial_id
json.(issue, :title, :status)
json.labels issue.labels do |label|
  json.partial! 'label', :label => label
end
json.assignee do
  json.partial! 'api/v1/shared/member', :member => issue.assignee
end if issue.assignee

json.url api_v1_project_issue_path(issue.project.id, issue.serial_id, :format => :json)


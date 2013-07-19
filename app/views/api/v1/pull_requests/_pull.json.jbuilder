json.number pull.serial_id
json.(pull, :title, :status)
json.to_ref do
  json.ref pull.to_ref
  json.sha pull.to_commit.try(:id)
  json.project do
    json.partial! 'api/v1/projects/project', :project => pull.to_project
  end
end
json.from_ref do
  json.ref pull.from_ref
  json.sha pull.from_commit.try(:id)
  json.project do
    json.partial! 'api/v1/projects/project', :project => pull.from_project
  end
end
json.partial! 'api/v1/shared/owner', :owner => pull.user
json.assignee do
  json.partial! 'api/v1/shared/member', :member => pull.issue.assignee
end if pull.issue.assignee
json.mergeable pull.can_merging?
json.merged_at pull.issue.closed_at.to_i if pull.merged?

json.url api_v1_project_pull_request_path(pull.to_project.id, pull.id, :format => :json)

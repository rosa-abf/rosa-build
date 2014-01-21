json.issue do
  json.partial! 'issue', issue: @issue
  json.issue @issue.body
  json.partial! 'api/v1/shared/owner', owner: @issue.user
  json.closed_at @issue.closed_at.to_i
  json.closed_by do
    json.partial! 'api/v1/shared/member', member: @issue.closer
  end if @issue.closer
  json.created_at @issue.created_at.to_i
  json.updated_at @issue.updated_at.to_i
end

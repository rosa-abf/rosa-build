json.issues @issues do |json, issue|
  json.partial! 'issue', :issue => issue, :json => json
  json.issue issue.body
  json.partial! 'api/v1/shared/owner', :owner => issue.user
  json.closed_at issue.closed_at.to_i
  json.closed_by do |json_user|
    json.partial! 'api/v1/shared/member', :member => issue.closer, :tag => json_user
  end if issue.closer
  json.created_at issue.created_at.to_i
  json.updated_at issue.updated_at.to_i
end

json.groups @groups do |group|
  json.(group, :id, :uname, :own_projects_count, :description)
  json.created_at group.created_at.to_i
  json.updated_at group.updated_at.to_i
  json.partial! 'api/v1/shared/owner', owner: group.owner
  json.avatar_url avatar_url(group, :big)
  json.url api_v1_group_path(group.id, format: :json)
  json.html_url group_path(group.uname)
end

json.url api_v1_groups_path(format: :json)
json.id advisory.advisory_id
json.(advisory, :description)
json.platforms advisory.platforms do |platform|
  json.(platform, :id, :released)
  json.url api_v1_platform_path(platform.id, :format => :json)
end
json.projects advisory.projects do |project|
  json.(project, :id, :name)
  json.fullname project.name_with_owner
  json.url api_v1_project_path(project.id, :format => :json)
end
json.url api_v1_advisory_path(advisory.advisory_id, :format => :json)
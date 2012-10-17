json.projects @projects do |json, project|
  json.(project, :id, :name, :visibility, :description, :ancestry, :has_issues, :has_wiki, :default_branch, :is_package, :average_build_time)
  json.created_at project.created_at.to_i
  json.updated_at project.updated_at.to_i
  json.owner do |json_owner|
    json_owner.(project.owner, :id, :name)
    json_owner.type project.owner_type
    json_owner.url member_path(project.owner)
  end
  json.url api_v1_project_path(project.id, :format => :json)
end

json.url api_v1_projects_path(:format => :json)
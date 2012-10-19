json.projects @projects do |json, project|
  json.partial! 'project', :project => project, :json => json
  json.(project, :visibility, :description, :ancestry, :has_issues, :has_wiki, :default_branch, :is_package, :average_build_time)
  json.created_at project.created_at.to_i
  json.updated_at project.updated_at.to_i
  json.partial! 'api/v1/shared/owner', :owner => project.owner
end

json.url api_v1_projects_path(:format => :json)
json.projects @projects do |project|
  json.partial! 'project', project: project
  json.(project, :description, :ancestry, :has_issues, :default_branch, :is_package, :publish_i686_into_x86_64)
  json.created_at project.created_at.to_i
  json.updated_at project.updated_at.to_i
  json.partial! 'api/v1/shared/owner', owner: project.owner
end

json.url api_v1_projects_path(format: :json)
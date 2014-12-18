json.(project, :id, :name)
json.fullname project.name_with_owner
json.url api_v1_project_path(project.id, format: :json)
json.git_url git_repo_url(project.name_with_owner)
json.maintainer do
  if project.maintainer
    json.partial! 'api/v1/maintainers/maintainer', maintainer: project.maintainer
  end
end
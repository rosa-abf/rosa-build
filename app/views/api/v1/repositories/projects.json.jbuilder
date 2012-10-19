json.repository do |json|
  json.partial! 'repository', :repository => @repository, :json => json
  json.projects @projects do |json_project, project|
    json.partial! 'api/v1/projects/project',
      :project => project, :json => json_project
  end
end
json.url projects_api_v1_repository_path(@repository.id, :format => :json)
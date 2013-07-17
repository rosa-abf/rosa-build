json.repository do
  json.partial! 'repository', :repository => @repository
  json.projects @projects do |project|
    json.partial! 'api/v1/projects/project', :project => project
  end
end
json.url projects_api_v1_repository_path(@repository.id, :format => :json)
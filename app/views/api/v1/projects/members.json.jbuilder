json.project do |json|
  json.(@project, :id)
  json.partial! 'api/v1/shared/members'
end
json.url members_api_v1_project_path(@project.id, :format => :json)
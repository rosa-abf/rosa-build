json.project do |json|
  json.(@project, :id, :name, :visibility)
  json.partial! 'api/v1/shared/owner', :owner => @project.owner
  json.url api_v1_project_path(@project, :format => :json)
end

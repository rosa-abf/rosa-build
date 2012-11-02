json.project do |json|
  json.partial! 'project', :project => @project, :json => json
  json.(@project, :visibility)
  json.partial! 'api/v1/shared/owner', :owner => @project.owner
end

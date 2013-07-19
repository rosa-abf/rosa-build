json.project do
  json.partial! 'project', :project => @project
  json.(@project, :visibility)
  json.partial! 'api/v1/shared/owner', :owner => @project.owner
end

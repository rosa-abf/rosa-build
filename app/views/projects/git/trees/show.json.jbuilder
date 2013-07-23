json.project do
  json.partial! 'api/v1/projects/project', :project => @project
  json.owner do
    json.(@project.owner, :id, :name, :uname)
    json.type @project.owner.class.name
  end
end
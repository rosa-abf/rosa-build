json.project do
  json.(@project, :id, :name)
  json.fullname @project.name_with_owner

  json.owner do
    json.(@project.owner, :id, :name, :uname)
  end
end
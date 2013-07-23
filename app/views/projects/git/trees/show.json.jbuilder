json.project do
  json.(@project, :id, :name)

  json.owner do
    json.(@project.owner, :id, :name, :uname)
  end
end
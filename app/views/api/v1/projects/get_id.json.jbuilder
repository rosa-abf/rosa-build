json.project do |json|
  json.(@project, :id, :name, :visibility)
  json.owner do |json_owner|
    json_owner.(@project.owner, :id, :name)
    json_owner.type @project.owner_type
    json_owner.url @project.owner_type == 'User' ? user_path(@project.owner) : group_path(@project.owner)
  end
  json.url api_v1_project_path(@project, :format => :json)
end

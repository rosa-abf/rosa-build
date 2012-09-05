json.project do |json|
  json.(@project, :id, :name, :visibility, :description, :ancestry, :has_issues, :has_wiki,
                  :srpm_file_name, :srpm_content_type, :srpm_file_size, :srpm_updated_at, :default_branch, :is_package,
                  :average_build_time, :build_count)
  json.created_at @project.created_at.to_i
  json.updated_at @project.updated_at.to_i
  json.owner do |json_owner|
    json_owner.(@project.owner, :id, :name)
    json_owner.type @project.owner_type
    json_owner.url @project.owner_type == 'User' ? user_path(@project.owner) : group_path(@project.owner)
  end
end

json.url api_v1_project_path(@project, :format => :json)

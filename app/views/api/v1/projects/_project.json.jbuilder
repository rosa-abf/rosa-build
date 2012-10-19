json.(project, :id, :name)
json.fullname project.name_with_owner
json.url api_v1_project_path(project.id, :format => :json)
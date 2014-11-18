json.projects @projects do |project|
  json.(project, :name, :description)
  json.path           project_path(project)
  json.public         project.public?
  json.updated_at     project.updated_at
  json.updated_at_utc project.updated_at.strftime('%Y-%m-%d %H:%M:%S UTC')
end

json.total_items @total_items
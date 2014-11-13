json.projects @projects do |project|
  json.(project, :name, :description)
  json.path project_path(project)
end

json.total_items @total_items
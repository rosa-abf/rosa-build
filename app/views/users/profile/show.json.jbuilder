json.projects @projects do |project|
  json.(project, :name, :description)
  json.path     project_path(project)
  json.public   project.public?
  json.updated  time_ago_in_words(project.updated_at)
end

json.total_items @total_items
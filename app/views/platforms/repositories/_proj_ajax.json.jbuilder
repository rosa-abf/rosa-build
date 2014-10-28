json.projects @projects do |project|
  json.visibility_class fa_visibility_icon(project)
  json.path             project_path(project.name_with_owner)
  json.name             project.name_with_owner
  json.description      truncate(project.description || '', length: 60).gsub(/\n|\r|\t/, ' ')
  json.add_path         url_for(controller: :repositories, action: :add_project, project_id: project.id)
end

json.pages angularjs_will_paginate(@projects)
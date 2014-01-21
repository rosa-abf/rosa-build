projs = @projects.map do |project|
  [
    link_to(project.name_with_owner, project),
    truncate(project.description || '', length: 60).gsub(/\n|\r|\t/, ' '),
    link_to(t("layout.add"), url_for(controller: :repositories, action: :add_project, project_id: project.id))
  ]
end

json.sEcho                params[:sEcho] || -1
json.iTotalRecords        @total_projects
json.iTotalDisplayRecords @projects.count
json.aaData               projs

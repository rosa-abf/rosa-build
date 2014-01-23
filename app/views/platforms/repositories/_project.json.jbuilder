 projs = @projects.map do |pr|
   [
     content_tag(:div, image_tag(visibility_icon(pr.visibility)), class: 'table-sort-left') +
     content_tag(:div, link_to(pr.name_with_owner, pr), class: 'table-sort-right'),

     truncate(pr.description || '', length: 60).gsub(/\n|\r|\t/, ' '),

     if can? :remove_project, @repository
       link_to(
         remove_project_platform_repository_path(@platform, @repository, project_id: pr.id),
         method: :delete, confirm: t("layout.confirm")) do
           content_tag(:span, "&nbsp;".html_safe, class: 'delete')
       end
     else
       ''
     end
   ]
 end

json.sEcho                  params[:sEcho].to_i || -1
json.iTotalRecords          @total_projects
json.iTotalDisplayRecords   @projects.count
json.aaData                 projs

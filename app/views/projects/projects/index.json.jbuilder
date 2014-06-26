json.projects do
  json.array!(@projects) do |item|
    alone_member = alone_member?(item)
    json.cache! item, expires_in: 10.minutes do
      json.visibility_class   fa_visibility_icon(item)
      json.name_with_owner    item.name_with_owner
      json.link               project_path(item)
      json.description        item.description
      json.participant_class  participant_class(alone_member, item)
      json.user_role_name     t("layout.collaborators.role_names.#{current_user.best_role item}")
      json.can_leave_project  item.owner != current_user && alone_member
    end
  end
end

json.page              params[:page]
json.projects_count   @projects_count

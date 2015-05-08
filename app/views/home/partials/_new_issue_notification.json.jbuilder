json.project_link project_path(project_name_with_owner)
json.issue do
  json.title item.data[:issue_title]

  if item.data[:issue_serial_id].present?
    is_pull = @project.issues.where(serial_id: item.data[:issue_serial_id]).joins(:pull_request).exists?
    json.is_pull is_pull
    if is_pull
      json.link project_pull_request_path(project_name_with_owner, item.data[:issue_serial_id])
    else
      json.link project_issue_path(project_name_with_owner, item.data[:issue_serial_id])
    end
  end
end

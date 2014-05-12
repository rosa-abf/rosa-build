json.project_link project_path(project_name_with_owner)
json.issue do
  json.title item.data[:issue_title]
  json.link project_issue_path(project_name_with_owner, item.data[:issue_serial_id]) if item.data[:issue_serial_id].present?
end

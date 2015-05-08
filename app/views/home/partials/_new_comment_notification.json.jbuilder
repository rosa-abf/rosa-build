json.issue do
  if item.data[:issue_serial_id].present?
    is_pull = @project.issues.where(serial_id: item.data[:issue_serial_id]).joins(:pull_request).exists?
    json.is_pull is_pull
    if is_pull
      json.link project_pull_request_path(project_name_with_owner, item.data[:issue_serial_id])
    else
      json.link project_issue_path(project_name_with_owner, item.data[:issue_serial_id])
    end
  end
  json.title short_message(item.data[:issue_title], 50)
  json.read_more item.data[:comment_id]
end
json.body markdown(short_message(item.data[:comment_body], 100))

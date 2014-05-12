json.issue do
  json.link project_issue_path(project_name_with_owner, item.data[:issue_serial_id]) if item.data[:issue_serial_id].present?
  json.title short_message(item.data[:issue_title], 50)
  json.read_more item.data[:comment_id]
end
json.body markdown(short_message(item.data[:comment_body], 100))

json.project_link project_path(project_name_with_owner)
json.build_list do
  json.id item.data[:build_list_id]
  json.link build_list_path(item.data[:build_list_id])
  json.status_message get_feed_build_list_status_message(item.data[:status])
end

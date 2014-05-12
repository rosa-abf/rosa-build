json.project_link project_path(project_name_with_owner)
json.commit do
  json.link commit_path(project_name_with_owner, item.data[:commit_id]) if item.data[:commit_id].present?
  json.hash shortest_hash_id(item.data[:commit_id])
  json.message markdown(short_message(item.data[:commit_message], 70))
  json.read_more item.data[:comment_id]
end
json.body markdown(short_message(item.data[:comment_body], 100))

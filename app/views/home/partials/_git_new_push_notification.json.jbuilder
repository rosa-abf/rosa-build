json.change_type item.data[:change_type]
json.project_link project_path(project_name_with_owner)
json.branch_name item.data[:branch_name]

json.last_commits do
  json.array! item.data[:last_commits] do |commit|
    json.hash shortest_hash_id(commit[0])
    json.message markdown(short_message(commit[1], 70))
    json.link commit_path(project_name_with_owner, commit[0])
  end
end
if item.data[:other_commits].present?
  json.other_commits t('notifications.bodies.more_commits', count: item.data[:other_commits_count], commits: commits_pluralize(item.data[:other_commits_count]))
  json.other_commits_path diff_path(project_name_with_owner, diff: item.data[:other_commits])
end

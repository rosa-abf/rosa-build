json.array!(@activity_feeds) do |item|
  json.cache! item do
    json.date item.created_at
    json.kind item.kind
    user = get_user_from_activity_item(item)
    json.user do
      json.link user_path(user) if user.persisted?
      json.image avatar_url(user, :small) if user.persisted?
      json.uname (user.fullname || user.email)
    end if user
    project_name_with_owner = "#{item.data[:project_owner]}/#{item.data[:project_name]}"
    json.project_name_with_owner project_name_with_owner
    path = get_path_from_activity_item(item, project_name_with_owner: project_name_with_owner)
    json.title get_title_from_activity_item(item, user: user, project_name_with_owner: project_name_with_owner, path: path)

    case item.kind
    when 'new_comment_notification'
      json.read_more path + "#comment#{item.data[:comment_id]}"
      json.body short_message(item.data[:comment_body], 1000)
    when 'git_new_push_notification'
      json.body render('commits_list', item: item, project_name_with_owner: project_name_with_owner).html_safe
    end
    json.id item.id
  end
end
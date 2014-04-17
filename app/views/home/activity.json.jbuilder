json.array!(@activity_feeds) do |item|
  #json.cache! item, expires_in: 10.minutes do
    json.date item.created_at
    json.kind item.kind
    user = get_user_from_activity_item(item)
    json.user do
      json.link user_path(user) if user.persisted?
      json.image avatar_url(user, :small) if user.persisted?
      json.uname (user.fullname || user.email)
    end if user

    project_name_with_owner = "#{item.data[:project_owner]}/#{item.data[:project_name]}"
    @project = Project.find_by_owner_and_name(item.data[:project_owner], item.data[:project_name])

    json.project_name_with_owner project_name_with_owner

    case item.kind
    when 'new_comment_notification'
      json.issue do
        json.link project_issue_path(project_name_with_owner, item.data[:issue_serial_id]) if item.data[:issue_serial_id].present?
        json.title short_message(item.data[:issue_title], 50)
        json.read_more item.data[:comment_id]
      end
      json.body markdown(short_message(item.data[:comment_body], 100))

    when 'git_new_push_notification'
      json.change_type item.data[:change_type]
      json.project_link project_path(project_name_with_owner)
      json.branch_name item.data[:branch_name]

      json.last_commits do
        json.array! item.data[:last_commits] do |commit|
          json.hash shortest_hash_id(commit[0])
          json.message markdown(short_message(commit[1], 70))
          json.commit_path commit_path(project_name_with_owner, commit[0])
        end
      end
      if item.data[:other_commits].present?
        json.other_commits t('notifications.bodies.more_commits', count: item.data[:other_commits_count], commits: commits_pluralize(item.data[:other_commits_count]))
        json.other_commits_path diff_path(project_name_with_owner, diff: item.data[:other_commits])
      end

    when 'git_delete_branch_notification'
      json.branch_name item.data[:branch_name]
      json.project_link project_path(project_name_with_owner)

    when 'new_issue_notification'
      json.project_link project_path(project_name_with_owner)
      json.issue do
        json.title item.data[:issue_title]
        json.link project_issue_path(project_name_with_owner, item.data[:issue_serial_id]) if item.data[:issue_serial_id].present?
      end

    when 'new_user_notification'
      json.user_name item.data[:user_name]

    when 'wiki_new_commit_notification'
      json.wiki_link history_project_wiki_index_path(project_name_with_owner)
      json.project_link project_path(project_name_with_owner)
    end
    json.id item.id
  #end
end
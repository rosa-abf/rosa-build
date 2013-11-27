json.user do
  json.(@user, :id)
  json.notifiers do
    json.(@user.notifier, :can_notify, :new_comment, :new_comment_reply, :new_issue, :issue_assign, :new_comment_commit_owner, :new_comment_commit_repo_owner, :new_comment_commit_commentor, :new_build, :new_associated_build,
    :update_code)
  end
end

json.url notifiers_api_v1_user_path(:json)
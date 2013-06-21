json.commits @commits do |json_commit, commit|
  json_commit.sha commit.id
  json_commit.https_url commit_path(@project, commit.id)
  json.author do |json_author|
    json_author.name commit.author.name
    json_author.email commit.author.email
    json_author.date commit.authored_date.to_i
  end
  json.committer do |json_committer|
    json_committer.name commit.committer.name
    json_committer.email commit.committer.email
    json_committer.date commit.committed_date.to_i
  end
  json.message commit.message
  json.tree do |json_tree|
    json_tree.sha commit.id
    json_tree.https_url commit_path(@project, commit.id)
  end
  json.parents commit.parents do |json, parent|
    json.sha parent.id
    json.https_url commit_path(@project, parent.id)
  end
end

json.url commits_api_v1_project_pull_request_path(:format => :json)

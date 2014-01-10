json.commits @commits do |commit|
  json.sha commit.id
  json.https_url commit_path(@project, commit.id)
  json.author do
    json.name commit.author.name
    json.email commit.author.email
    json.date commit.authored_date.to_i
  end
  json.committer do
    json.name commit.committer.name
    json.email commit.committer.email
    json.date commit.committed_date.to_i
  end
  json.message commit.message
  json.tree do
    json.sha commit.id
    json.https_url commit_path(@project, commit.id)
  end
  json.parents commit.parents do |parent|
    json.sha parent.id
    json.https_url commit_path(@project, parent.id)
  end
end

json.url commits_api_v1_project_pull_request_path(:format => :json)

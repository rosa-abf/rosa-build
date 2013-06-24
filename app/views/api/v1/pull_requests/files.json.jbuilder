json.files @stats do |json_stat, stat|
  fstat, diff = stat
  commit_id = diff.deleted_file ? @pull.to_commit.id : @pull.from_commit.id
  json_stat.sha commit_id
  json_stat.filename diff.b_path
  status = case
           when diff.new_file
             'added'
           when diff.deleted_file
             'deleted'
           when diff.renamed_file
             'renamed'
           else
             'modified'
           end
  json_stat.status status
  json_stat.additions fstat.additions
  json_stat.deletions fstat.deletions
  json_stat.changes   fstat.additions + fstat.deletions
  json_stat.blob_https_url blob_path(@project, commit_id, diff.b_path)
  json_stat.raw_https_url  raw_path(@project, commit_id, diff.b_path)
end

json.url files_api_v1_project_pull_request_path(:format => :json)

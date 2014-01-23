json.files @stats do |stat|
  fstat, diff = stat
  commit_id = diff.deleted_file ? @pull.to_commit.id : @pull.from_commit.id
  json.sha commit_id
  json.filename diff.b_path
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
  json.status status
  json.additions fstat.additions
  json.deletions fstat.deletions
  json.changes   fstat.additions + fstat.deletions
  json.blob_https_url blob_path(@project, commit_id, diff.b_path)
  json.raw_https_url  raw_path(@project, commit_id, diff.b_path)
end

json.url files_api_v1_project_pull_request_path(format: :json)

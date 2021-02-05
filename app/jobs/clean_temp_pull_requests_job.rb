class CleanTempPullRequestsJob
  @queue = :low

  def self.perform
    path = File.join(APP_CONFIG['git_path'], 'temp_pull_requests')
    `sh -c "cd #{path} && find -mindepth 3 -maxdepth 3 -type d -mtime +0 | xargs rm -rf && find -maxdepth 2 -type d -empty -delete"`
  end
end
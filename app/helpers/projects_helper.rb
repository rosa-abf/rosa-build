module ProjectsHelper
  def git_repo_url(name)
    port = APP_CONFIG['ssh_port'] || 22
    if port == 22
      "git@#{request.host}:#{name}.git"
    else
      "ssh://git@#{request.host}:#{port}/#{name}.git"
    end
  end
end

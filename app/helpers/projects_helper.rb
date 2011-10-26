module ProjectsHelper
  def git_repo_url(name)
    "ssh://git@#{request.domain}:722/#{name}.git"
  end
end

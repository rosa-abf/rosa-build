module ProjectsHelper
  def git_repo_url(name)
    "ssh://git@#{request.host}:1822/#{name}.git"
  end
end

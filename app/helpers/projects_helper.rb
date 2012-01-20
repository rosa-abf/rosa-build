module ProjectsHelper
  def git_repo_url(name)
    if current_user
      "http://#{current_user.uname}@#{request.host_with_port}/#{name}.git"
    else
      "http://#{request.host_with_port}/#{name}.git"
    end
  end

  def git_wiki_repo_url(name)
    git_repo_url("#{name}.wiki")
  end
end

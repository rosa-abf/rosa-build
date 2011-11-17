module ProjectsHelper
  def git_repo_url(name, read_only = true)
    if current_user and !read_only
      "http://#{current_user.uname}@#{request.host_with_port}/#{name}.git"
    else
      "http://#{request.host_with_port}/#{name}.git"
    end
  end
end

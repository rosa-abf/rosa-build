# -*- encoding : utf-8 -*-
module ProjectsHelper
  def git_repo_url(name)
    if current_user
      "http://#{current_user.uname}@#{request.host_with_port}/#{name}.git"
    else
      "http://#{request.host_with_port}/#{name}.git"
    end
  end
end

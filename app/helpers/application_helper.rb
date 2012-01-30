# -*- encoding : utf-8 -*-
module ApplicationHelper
  def choose_title
    title = if ['categories', 'personal_repositories', 'downloads'].include?(controller.controller_name)
      APP_CONFIG['repo_project_name']
    else
      APP_CONFIG['project_name']
    end
    
    return title
  end
end

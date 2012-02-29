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

  def layout_class
    case
    when params[:controller] == 'issues' && params[:action] == 'new'
      'nopadding'
    when params[:controller] == 'build_lists'
      'slim'
    else
      nil
    end
  end
end

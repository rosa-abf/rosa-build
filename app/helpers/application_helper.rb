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
      'right nopadding'
    when params[:controller] == 'build_lists' && params[:action] == 'index'
      'right slim'
    when params[:controller] == 'build_lists' && ['new', 'create'].include?(params[:action])
      nil
    when params[:controller] == 'platforms' && params[:action] == 'show'
      'right bigpadding'
    else
      content_for?(:sidebar) ? 'right' : 'all'
    end
  end
end

# -*- encoding : utf-8 -*-
module ApplicationHelper
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
    when params[:controller] == 'platforms' && params[:action] == 'clone'
      'right middlepadding'
    else
      content_for?(:sidebar) ? 'right' : 'all'
    end
  end

  def title_project project
    "#{t 'activerecord.models.project'} #{project.owner.uname}/#{project.name}"
  end

  def title_platform platform
    "#{t 'activerecord.models.platform'} #{platform.owner.uname}/#{platform.name}"
  end

  def title_group group
    "#{t 'activerecord.models.group'} #{group.uname}"
  end
end

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

  def title_object object
    name = object.class == Group ? object.uname : object.name
    object_name = t "activerecord.models.#{object.class.name.downcase}"
    case object.class.name
    when 'Project', 'Platform'
      "#{object_name} #{object.owner.uname}/#{object.name}"
    when 'Repository', 'Product'
      "#{object_name} #{object.name} - #{title_object object.platform}"
    when 'Group'
      "#{object_name} #{object.uname}"
    else object.class.name
    end
  end
end

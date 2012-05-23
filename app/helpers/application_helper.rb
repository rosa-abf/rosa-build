# -*- encoding : utf-8 -*-
module ApplicationHelper
  def layout_class
    case
    when controller_name == 'issues' && action_name == 'new'
      'right nopadding'
    when controller_name == 'build_lists' && action_name == 'index'
      'right slim'
    when controller_name == 'build_lists' && ['new', 'create'].include?(action_name)
      nil
    #when controller_name == 'platforms' && action_name == 'build_all'
    #  nil
    when controller_name == 'platforms' && action_name == 'show'
      'right bigpadding'
    when controller_name == 'platforms' && action_name == 'clone'
      'right middlepadding'
    else
      content_for?(:sidebar) ? 'right' : 'all'
    end
  end

  def top_menu_class(base)
    (controller_name.include?('build_lists') ? controller_name : params[:controller]).include?(base.to_s) ? 'active' : nil
  end

  def title_object object
    return object.advisory_id if object.class == Advisory
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

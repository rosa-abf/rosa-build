module ApplicationHelper

  def submit_button_tag(icon_class: 'fa-check', text: nil)
    text ||= I18n.t('layout.save')
    button_tag type: :submit,
        data:  {'disable-with' => I18n.t('layout.processing')},
        class: 'btn btn-primary' do
      content_tag(:i, nil, class: ['fa', icon_class]) << ' '<< text
    end
  end

  def layout_class
    case
    when controller_name == 'issues' && action_name == 'new'
      'right nopadding'
    when controller_name == 'build_lists' && ['new', 'create'].include?(action_name)
      nil
    when controller_name == 'platforms' && ['build_all', 'mass_builds'].include?(action_name)
      'right slim'
    when controller_name == 'platforms' && action_name == 'show'
      'right bigpadding'
    when controller_name == 'platforms' && action_name == 'clone'
      'right middlepadding'
    when controller_name == 'contacts' && action_name == 'sended'
      'all feedback_sended'
    else
      content_for?(:sidebar) ? 'right' : 'all'
    end
  end

  def top_menu_class(base)
    (controller_name.include?('build_lists') ? controller_name : params[:controller]).include?(base.to_s) ? 'active' : nil
  end

  # Public: Get icon css class.
  #
  # base - the tab (Symbol).
  #
  # Returns String css class.
  def top_menu_icon(base)
    case base
    when :platforms
      'fa-linux'
    when :projects
      'fa-cube'
    when :build_lists
      'fa-cogs'
    when :groups
      'fa-users'
    when :advisories
      'fa-newspaper-o'
    when :statistics
      'fa-area-chart'
    end
  end

  def title_object(object)
    return object.advisory_id if object.class == Advisory
    name = object.class == Group ? object.uname : object.name
    object_name = t "activerecord.models.#{object.class.name.downcase}"
    case object.class.name
    when 'Project'
      "#{object_name} #{object.owner.uname}/#{object.name}"
    when 'Platform'
      if object.main?
        "#{object_name} #{object.name}"
      else
        "#{object_name} #{object.owner.uname}/#{object.name}"
      end
    when 'Repository', 'Product'
      "#{object_name} #{object.name} - #{title_object object.platform}"
    when 'Group'
      "#{object_name} #{object.uname}"
    else object.class.name
    end
  end

  def local_alert(text, type = 'error')
    html = "<div class='flash'><div class='alert #{type}'> #{text}"
    html << link_to('×', '#', class: 'close close-alert', 'data-dismiss' => 'alert')
    html << '</div></div>'
  end

  # Why 42? Because it is the Answer!
  def short_message(message, length = 42)
    truncate(message, length: length, omission: '…')
  end

  def datetime_moment(date, options = {})
    tag = options[:tag] || :div
    klass = "datetime_moment #{options[:class]}"
    content_tag(tag, nil, class: klass, origin_datetime: date)
  end

  def alert_class(type)
    case type
    when 'error', 'alert'
      'alert-danger'
    when 'notice'
      'alert-success'
    else
      "alert-#{type}"
    end
  end

  def bytes_to_size(bytes)
    sizes = [0, 1024, 1024*1024, 1024*1024*1024]
    names = ['B', 'KiB', 'MiB', 'GiB']
    sizes.each_with_index do |l, i|
      low, high = sizes[i], sizes[i+1]
      if bytes >= low && (!high || bytes < high)
        if low == 0
          sz = bytes
        else
          sz = (bytes.to_f / low).round(2)
        end
        return "#{sz}#{names[i]}"
      end
    end
  end
end

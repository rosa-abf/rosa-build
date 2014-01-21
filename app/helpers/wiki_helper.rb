module WikiHelper

  def revert_path(project, first, second, name)
    if name
      revert_page_project_wiki_path(project, CGI.escape(name), first, second)
    else
      revert_project_wiki_index_path(project, first, second)
    end
  end

  def compare_path(project, name)
    if name
      compare_project_wiki_path(@project, CGI.escape(name))
    else
      compare_project_wiki_index_path(@project)
    end
  end

  def escaped_name
    CGI.escape(@name)
  end

  def editor_path(project, name)
    if @new
      url_for(controller: :wiki, action: :create, project_id: project.id)
    else
      url_for(controller: :wiki, action: :update, project_id: project.id, id: name)
    end
  end

  def view_path(project, name)
    name == 'Home' ? project_wiki_index_path(project) : project_wiki_path(project, name)
  end

  def wiki_formats
    APP_CONFIG['wiki_formats'].map do |key, val|
      [ val, key.to_s ]
    end.sort do |a, b|
      a.first.downcase <=> b.first.downcase
    end
  end

  def footer
    if @footer.nil?
      @footer = !!@page.footer ? @page.footer : false
    end
    @footer
  end

  def sidebar
    if @sidebar.nil?
      @sidebar = !!@page.sidebar ? @page.sidebar : false
    end
    @sidebar
  end

  def has_footer?
    @footer = (@page.footer || false) if @footer.nil? && @page
    !!@footer
  end

  def has_sidebar?
    @sidebar = (@page.sidebar || false) if @sidebar.nil? && @page
    !!@sidebar
  end

  def footer_content
    has_footer? && @footer.formatted_data
  end

  def footer_format
    has_footer? && @footer.format.to_s
  end

  def sidebar_content
    has_sidebar? && @sidebar.formatted_data
  end

  def sidebar_format
    has_sidebar? && @sidebar.format.to_s
  end

  def author
    @page.version.author.name
  end

  def author_email
    @page.version.author.email
  end

  def user_path_by_user(user)
    (user.present?) ? user_path(user) : 'javascript:void(0)'
  end

  def user_link_by_user(user)
    link_to (user.present?) ? user.uname : author, user_path_by_user(user)
  end

  def date
    @page.version.authored_date
  end

  def format
    @new ? 'markdown' : @page.format
  end
end

module WikiHelper

  def gravatar_url(email)
    "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email.downcase)}?s=16&r=pg"
  end

  def escaped_name
    CGI.escape(@name)
  end

  def editor_path(project, name)
    if @new
      url_for(:controller => :wiki, :action => :create, :project_id => project.id)
    else
      url_for(:controller => :wiki, :action => :update, :project_id => project.id, :id => name)
    end
  end

  def view_path(project, name)
    name == 'Home' ? project_wiki_index_path(project) : project_wiki_path(project, name)
  end

  def formats
    Gollum::Page::FORMAT_NAMES.map do |key, val|
      [ val, key.to_s ]
    end.sort do |a, b|
      a.first.downcase <=> b.first.downcase
    end
  end

  def footer
    if @footer.nil?
      @footer = !!@page.footer ? @page.footer.raw_data : false
    end
    @footer
  end

  def sidebar
    if @sidebar.nil?
      @sidebar = !!@page.sidebar ? @page.sidebar.raw_data : false
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

  def date
    @page.version.authored_date.strftime("%Y-%m-%d %H:%M:%S")
  end

  def format
    @new ? 'markdown' : @page.format
  end
end

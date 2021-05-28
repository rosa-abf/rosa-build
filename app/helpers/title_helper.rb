module TitleHelper
  def set_page_title(title)
    @current_page_title = title
  end

  alias_method :title, :set_page_title

  def get_page_title(opts = {})
    title = (@current_page_title && [@current_page_title]) || []

    site_title = opts[:site].presence
    title.unshift(site_title) if site_title
    title = title.flatten.map(&method(:strip_tags))

    title.reverse!
    title = safe_join(title, ' - ')

    title
  end
end

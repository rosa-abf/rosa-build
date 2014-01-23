class Array
  def html_safe
    self
  end
end

class AngularjsLinkRenderer < WillPaginate::ActionView::LinkRenderer

  def to_html
    pagination.map do |item|
      item.is_a?(Fixnum) ? page_number(item) : send(item)
    end
  end

  protected

  def page_number(page)
    unless page == current_page
      {active: true, number: page, type: :page}
    else
      {active: false, number: page, type: :first}
    end
  end

  def gap
    nil
  end

  def next_page
    num = @collection.current_page < @collection.total_pages && @collection.current_page + 1
    previous_or_next_page(num, @options[:next_label], :next_page)
  end

  def previous_or_next_page(page, text, classname)
    if page
      {active: true, number: page, type: classname}
    else
      {active: false, number: page, type: classname}
    end
  end
end

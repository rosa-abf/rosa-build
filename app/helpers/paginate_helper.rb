module PaginateHelper

  def paginate_params
    per_page = params[:per_page].to_i
    per_page = 20 if per_page < 1
    per_page = 100 if per_page >100
    page = params[:page].to_i
    page = nil if page == 0
    {page: page, per_page: per_page}
  end

  def will_paginate(collection_or_options = nil, options = {})
    if collection_or_options.is_a? Hash
      options, collection_or_options = collection_or_options, nil
    end
    options.merge!(renderer: BootstrapLinkRenderer) unless options[:renderer]
    options.merge!(next_label: I18n.t('datatables.next_label')) unless options[:next_label]
    options.merge!(previous_label: I18n.t('datatables.previous_label')) unless options[:previous_label]
    super *[collection_or_options, options].compact
  end

  def angularjs_paginate(options = {})
    return if options[:per_page].blank?

    options.reverse_merge!(
      {
        total_items: 'total_items',
        page:        'page',
        ng_show:     "total_items > #{options[:per_page]}",
        select_page: "goToPage(page)"
      }
    )

    render 'shared/angularjs_paginate', options
  end
end

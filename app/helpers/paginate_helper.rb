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

  def angularjs_will_paginate(collection_or_options = nil, options = {})
    if collection_or_options.is_a? Hash
      options, collection_or_options = collection_or_options, nil
    end
    options.merge!(renderer: AngularjsLinkRenderer) unless options[:renderer]
    options.merge!(next_label: I18n.t('datatables.next_label')) unless options[:next_label]
    options.merge!(previous_label: I18n.t('datatables.previous_label')) unless options[:previous_label]
    will_paginate *[collection_or_options, options].compact
  end

  def paginate(options)
    return nil if options.blank?
    render 'shared/paginate',
      total_items: options[:total_items],
      page:        options[:page],
      per_page:    options[:per_page],
      ng_show:     options[:ng_show],
      select_page: options[:select_page]
  end
end

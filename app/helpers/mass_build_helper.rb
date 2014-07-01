module MassBuildHelper

  COLUMNS = [
    {
      sortable: true
    },
    {
      type:       'html',
      sortable:   false,
      searchable: false
    },
    {
      sortable:   false,
      searchable: false
    },
    {
      sortable:   false,
      searchable: false
    },
    {
      sortable:   false,
      searchable: false,
      class:      'buttons'
    }
  ]

  def link_to_list platform, mass_build, which
    link_to t("layout.mass_builds.#{which}"),
      get_list_platform_mass_build_path(platform, mass_build, kind: which, format: :txt),
      target: "_blank" if can?(:get_list, mass_build)
  end

  def link_to_mass_build(mass_build)
    link_to mass_build.name, build_lists_path+"#?#{{filter: {mass_build_id: mass_build.id, ownership: 'everything'}}.to_param}"
  end

  def mass_builds_datatable(platform)
    datatable(
      COLUMNS,
      {
        sort_by:            "[0, 'desc']",
        search_label:       '',
        placeholder:        t('layout.mass_builds.placeholder.description'),
        processing:         t('layout.processing'),
        pagination_labels:  {
          previous: t('datatables.previous_label'),
          next:     t('datatables.next_label')
        },
        empty_label:        t('datatables.empty_label'),
        info_label:         t('datatables.info_label'),
        info_empty_label:   t('datatables.info_empty_label'),
        filtered_label:     t('datatables.filtered_label'),
        table_dom_id:       'datatable',
        auto_width:         'false',
        ajax_source:        platform_mass_builds_path(platform, format: :json)
      }
    )
  end

end

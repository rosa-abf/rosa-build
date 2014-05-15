module RepositoriesHelper

  COLUMNS = [
    { type: 'html' },
    {
      type:       'html',
      sortable:   false,
      searchable: false
    },
    {
      type:       nil,
      sortable:   false,
      searchable: false,
      class:      'buttons'
    }
  ]

  def repository_projects_datatable(repository)
    datatable(
      COLUMNS,
      {
        sort_by:            "[0, 'asc']",
        # search_label:       t('layout.search_by_name'),
        search_label:       '',
        placeholder:        t('layout.projects.placeholder.project_name'),
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
        ajax_source:        datatable_ajax_source(repository)
      }
    )
  end

  private

  def datatable_ajax_source(repository)
    url_for(
      controller: :repositories,
      action:     :projects_list,
      id:         repository.id,
      added:      controller.action_name.to_sym == :show,
      format:     :json
    )
  end

end

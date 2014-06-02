module RailsDatatables
  def datatable(columns, opts={})
    sort_by = opts[:sort_by] || nil
    additional_data = opts[:additional_data] || {}
    search = opts[:search].present? ? opts[:search].to_s : "true"
    search_label = opts[:search_label] || "Search"
    placeholder  = opts[:placeholder]
    processing = opts[:processing] || "Processing"
    persist_state = opts[:persist_state].present? ? opts[:persist_state].to_s : "true"
    table_dom_id = opts[:table_dom_id] ? "##{opts[:table_dom_id]}" : ".datatable"
    per_page = opts[:per_page] || opts[:display_length]|| 25
    no_records_message = opts[:no_records_message] || nil
    auto_width = opts[:auto_width].present? ? opts[:auto_width].to_s : "true"
    row_callback = opts[:row_callback] || nil
    sdom = opts[:sdom] || nil

    empty_label      = opts[:empty_label]      if opts[:empty_label].present?
    info_label       = opts[:info_label]       if opts[:info_label].present?
    info_empty_label = opts[:info_empty_label] if opts[:info_empty_label].present?
    filtered_label   = opts[:filtered_label]   if opts[:filtered_label].present?

    if opts[:pagination_labels].present?
      pagination_labels = []
      pagination_labels << "'sFirst': '#{opts[:pagination_labels][:first]}'" if opts[:pagination_labels][:first].present?
      pagination_labels << "'sLast': '#{opts[:pagination_labels][:last]}'" if opts[:pagination_labels][:last].present?
      pagination_labels << "'sPrevious': '#{opts[:pagination_labels][:previous]}'" if opts[:pagination_labels][:previous].present?
      pagination_labels << "'sNext': '#{opts[:pagination_labels][:next]}'" if opts[:pagination_labels][:next].present?
      pagination_labels = pagination_labels.join(",\n")
    else
      pagination_labels = false
    end

    append = opts[:append] || nil

    ajax_source = opts[:ajax_source] || nil
    server_side = opts[:ajax_source].present?

    additional_data_string = ""
    additional_data.each_pair do |name,value|
      additional_data_string = additional_data_string + ", " if !additional_data_string.blank? && value
      additional_data_string = additional_data_string + "{'name': '#{name}', 'value':'#{value}'}" if value
    end

    %Q{
    <script type="text/javascript">
    $(function() {
        $('#{table_dom_id}').dataTable({
          "oLanguage": {
            "sSearch": "#{search_label}",
            #{"'sZeroRecords': '#{no_records_message}'," if no_records_message}
            #{"
              'oPaginate': {
                #{pagination_labels}
              },
            " if pagination_labels}

            #{"'sEmptyTable': '#{empty_label}',"      if empty_label}
            #{"'sInfo': '#{info_label}',"             if info_label}
            #{"'sInfoEmpty': '#{info_empty_label}',"  if info_empty_label}
            #{"'sInfoFiltered': '#{filtered_label}'," if filtered_label}

            "sProcessing": '#{processing}'
          },
          "sPaginationType": "will_paginate_like",
          "iDisplayLength": #{per_page},
          "bServerSide": #{server_side},
          "bLengthChange": false,
          "bStateSave": #{persist_state},
          "bFilter": #{search},
          "bAutoWidth": #{auto_width},
          #{"'aaSorting': [#{sort_by}]," if sort_by}
          #{"'sAjaxSource': '#{ajax_source}'," if ajax_source}
          #{"'sDom': '#{sdom}'," if sdom}
          "aoColumns": [
            #{formatted_columns(columns)}
          ],
          #{"'fnRowCallback': function( nRow, aData, iDisplayIndex ) { #{row_callback} }," if row_callback}
          #{"'fnServerData': function ( sSource, aoData, fnCallback ) {
            aoData.push( #{additional_data_string} );
            if (typeof dataTableAdditionalFilter == 'function') {
              aoData.push(dataTableAdditionalFilter());
            }
            $.getJSON( sSource, aoData, function (json) {
              fnCallback(json);
            } );
          }," if ajax_source}
          "bProcessing": true
        })#{append};

        $('#datatable_wrapper').append("<div class='both'></div>");
        #{ "$('#datatable_wrapper .dataTables_filter input').attr('placeholder', '#{placeholder}');" if placeholder }
    });
    </script>
    }
  end

  def format_columns_for_datatable(columns)
    formatted_columns(columns)
  end

  private
    def formatted_columns(columns)
      i = 0
      columns.map {|c|
        i += 1
        if c.nil? or c.empty?
          "null"
        else
          searchable = c[:searchable].to_s.present? ? c[:searchable].to_s : "true"
          sortable = c[:sortable].to_s.present? ? c[:sortable].to_s : "true"

          "{
          'sType': '#{c[:type] || "string"}',
          'bSortable':#{sortable},
          'bSearchable':#{searchable}
          #{",'sClass':'#{c[:class]}'" if c[:class]}
          }"
        end
      }.join(",")
    end
end

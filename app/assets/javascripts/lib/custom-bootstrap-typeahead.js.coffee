_.each $('input.typeahead'), (item) ->
  item = $(item)

  if item.data('id')
    onSelect = (i) ->
      $(item.data('id')).val i.value

  if item.attr('id') is 'to_project'
    onSelect = (data) ->
      pullUpdateToProject(data)

  item.typeahead
    ajax:     item.data('ajax')
    onSelect: onSelect

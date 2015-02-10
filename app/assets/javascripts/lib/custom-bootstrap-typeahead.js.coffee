_.each $('input.typeahead'), (item) ->
  item          = $(item)
  triggerLength = 1

  if item.data('id')
    onSelect = (i) ->
      $(item.data('id')).val i.value

  if item.attr('id') is 'to_project'
    onSelect = (data) ->
      pullUpdateToProject(data)
    triggerLength = 3

  item.typeahead
    ajax:
      url:           item.data('ajax')
      triggerLength: triggerLength
    onSelect:        onSelect

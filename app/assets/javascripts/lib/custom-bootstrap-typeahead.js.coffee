_.each $('input.typeahead'), (item) ->
  item = $(item)

  if item.data('id')
    onSelect = (i) ->
      $(item.data('id')).val i.value

  item.typeahead
    ajax:     item.data('ajax')
    onSelect: onSelect

_.each($('input.typeahead'), function(item) {
  item = $(item);
  var triggerLength = 1;
  var onSelect = null;

  if (item.data('id')) {
    onSelect = function(i) {
      $(item.data('id')).val(i.value);
    }
  }

  if (item.attr('id') === 'to_project') {
    onSelect = function(data) {
      pullUpdateToProject(data);
    }
    triggerLength = 3;
  }

  item.typeahead({
    ajax: {
      url: item.data('ajax'),
      triggerLength: triggerLength
    },
    onSelect: onSelect
  });
});

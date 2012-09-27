$(document).ready(function() {
  var upd_action = $('#update_action').val();
  var form = $('#new_pull_request');

  $('#pull_request_base_project').on('autocompleteselect', function(event, data){
    $('input#base_refs').autocomplete('option', 'source', data.item.refs);
  });

  $('#pull_request_base_project, input#base_refs, input#head_refs').on('autocompleteselect', function(event, data){
    form.attr('action', upd_action);
    form.attr('method', 'get');
    $('#update_pull').fadeIn('fast');
    $('#create_pull').fadeOut('fast');
  });

  $('#pull_tabs a').live('click', function (e) {
    var href = $(this).attr("href");

    if ( window.history && history.pushState ) {
      history.pushState("", "", href);
      history.replaceState("", "", href);
    } else {
      location.hash = href;
    }
  });
});

$(document).ready(function() {
  var upd_action = $('#update_action').val();
  var form = $('#new_pull_request');

  $('#pull_request_base_project').on('autocompleteselect', function(event, data){
    var ref = $('#base_ref');
    ref.parent().load(data.item.get_refs_url+' #base_ref', {"selected": ref.val()});
  });

  $('#pull_request_base_project, input#base_refs, input#head_refs').on('autocompleteselect', function(event, data){
    form.attr('action', upd_action)
        .attr('method', 'get');
    $('#update_pull').fadeIn('fast');
    $('#create_pull').fadeOut('fast');
  });

  $('#pull_tabs a').on('click', function (e) {
    var href = $(this).attr("href");

    if ( window.history && history.pushState ) {
      history.pushState("", "", href);
      history.replaceState("", "", href);
    } else {
      location.hash = href;
    }
  });
});

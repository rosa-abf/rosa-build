$(document).ready(function() {
  var upd_action = $('#update_action').val();
  var form = $('#new_pull_request');

  function updatePull(event, data) {
    form.attr('action', upd_action)
        .attr('method', 'get');
    $('#update_pull').fadeIn('fast');
    $('#create_pull').fadeOut('fast');
  };

  $('#pull_request_to_project').on('autocompleteselect', function(event, data){
    var ref = $('#to_ref');
    ref.parent().load(data.item.get_refs_url+' #to_ref', {"selected": ref.val()});
  });

  $('#pull_request_to_project').on('autocompleteselect', updatePull);
  $('select#to_ref, select#from_ref').on('change', updatePull);

  $('#pull_tabs a').on('click', function (e) {
    var href = $(this).attr("href");

    if ( window.history && history.pushState ) {
      history.pushState("", "", href);
      history.replaceState("", "", href);
    } else {
      location.hash = href;
    }
  });

  var diff_tab = $('#pull_tabs a[href="#diff"]');
  $('.link_to_full_changes').on('click', function(){
    diff_tab.tab('show');
  });
});

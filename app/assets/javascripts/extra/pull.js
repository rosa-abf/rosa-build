$(document).ready(function() {
  $('#pull_request_base_project').on('autocompleteselect', function(event, data){
    $('input#base_refs').autocomplete('option', 'source', data.item.refs);
  });

  $('#pull_request_base_project, input#base_refs, input#head_refs').on('autocompleteselect', function(event, data){
    var tmp = $('#update_action').val();
    $('#new_pull_request').attr('action', $('#update_action').val());
    $('#update_pull').fadeIn('fast');
    $('#create_pull').fadeOut('fast');
  });
});

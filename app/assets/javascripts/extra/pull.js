$(document).ready(function() {
  $('.edit_form.pull').live('submit', function() {
    var form = $(this);
    $.ajax({
      type: 'POST',
      url: form.attr("action"),
      data: form.serialize(),
      success: function(data){
                  form.fadeOut('slow');
                  $('#edit_pull_content').fadeIn('slow');
                  $('.rightlist.pull_title').html(form.find('#pull_title').attr('value'));
                  $('.rightlist.pull_body').html(form.find('#pull_body').attr('value'));
                },
      error: function(data){
               alert('error'); // TODO remove
             }
     });
    return false;
  });

  $('#edit_pull_content').live('click', function() {
    $('.edit_form.pull').fadeIn('fast');
    $(this).fadeOut('fast');
  });

  $('#cancel_edit_pull_content').live('click', function() {
    $('.edit_form.pull').fadeOut('fast');
    $('#edit_pull_content').fadeIn('fast');
  });

  $('#pull_request_base_project').on('autocompleteselect', function(event, data){
    $('input#base_refs').autocomplete('option', 'source', data.item.refs);
  });

  $('#pull_request_base_project, input#base_refs, input#head_refs').on('autocompleteselect', function(event, data){
    var tmp = $('#update_action').val();
    $('#new_pull_request').attr('action', $('#update_action').val());
    $('#update_pull').fadeIn('fast');
  });

});

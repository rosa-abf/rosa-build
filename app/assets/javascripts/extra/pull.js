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

});

$(document).ready(function() {
  $('.buttons a.edit_comment').live('click', function() {
    $(this).parent().parent().parent().hide();
    $('#open-comment'+'.comment.'+$(this).attr('id')).show();
    return false;
  });

  $('.cancel_edit_comment.button').live('click', function() {
    $(this).parent().parent().parent().hide();
    $('.buttons a.edit_comment#'+$(this).attr('id')).parent().parent().parent().show();
    return false;
  });

  $('form.edit_comment').live('submit', function() {
    var form = $(this);
    form.parent().find('.flash').remove();
    $.ajax({
      type: 'POST',
      url: form.attr("action"),
      data: form.serialize(),
      success: function(data){
                  var cancel_button = form.find('.cancel_edit_comment.button');
                  cancel_button.click();
                  $('.buttons a.edit_comment#'+cancel_button.attr('id')).parent().parent().find('.cm-s-default.md_and_cm').html(data).find('code').each(function (code) { CodeMirrorRun(this); })
                },
      error: function(data){
               form.before(data.responseText);
             }
     });
    return false;
  });


});

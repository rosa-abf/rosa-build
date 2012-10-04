$(document).ready(function() {
  var new_comment = $('#open-comment.comment.hidden.new_line_comment');

  $(document).on('click', '.buttons a.edit_comment', function() {
    $(this).parent().parent().parent().hide();
    $('#open-comment'+'.comment.'+$(this).attr('id')).show();
    return false;
  });

  $(document).on('click', '.cancel_edit_comment.button', function() {
    $(this).parent().parent().parent().hide();
    $('.buttons a.edit_comment#'+$(this).attr('id')).parent().parent().parent().show();
    return false;
  });

  $(document).on('submit', 'form.edit_comment', function() {
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

  $('.add_line-comment').on('click', function() {
    function ProcessData(data) {
      var str = "<tr><td class='line_numbers line_comments' colspan='2'></td>"+"<td>"+data+"</td></tr>";
      par.after(str);
      line.addClass('new_comment_exists');
      par.parent().find('#md_tabs.nav.nav-tabs').each(function(i) { $(this).find('a:first').tab('show') });
    }
    var line = $(this);
    var par = line.parent().parent();
    if(line.hasClass('new_comment_exists')) {
      $('#open-comment.new_line_comment').parent().parent().show();
    }
    else {
      $('#open-comment.new_line_comment').parent().parent().remove();
      $.get(line.attr('href'), null, ProcessData);
    }
    $('#new_line_edit_input').focus();
    return false;
  });

  $(document).on('click', '.cancel_inline_comment.button', function() {
    $(this).parent().parent().parent().parent().parent().hide();
    return false;
  });
});


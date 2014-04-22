$(document).ready(function() {
  var new_comment = $('#open-comment.comment.hidden.new_line_comment');

  $(document).on('click', '.buttons a.edit_comment', function() {
    $(this).parents('div.activity').hide()
                                   .next().show();
    return false;
  });

  $(document).on('click', '.cancel_edit_comment.button', function() {
    $(this).parents('#open-comment.comment').hide()
                                            .prev().show();
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
                  var id = cancel_button.attr('id').match(/\d+$/)[0];
                  cancel_button.click();
                  $('#comment'+id+', #diff-comment'+id).find('.cm-s-default.md_and_cm').html(data);
                },
      error: function(data){
               form.before(data.responseText);
             }
     });
    return false;
  });

  $('.new_inline_comment.button').on('click', function() {
    $(this).parents('tr').prev('tr').find("a[href='"+$(this).attr('href')+"']").click();
    return false;
  });

  $('.add_line-comment').on('click', function() {
    function ProcessData(data) {
      if (inline_comment) {
        var str = "<tr class='inline-comments'><td class='line_numbers' colspan='2'></td><td>"+data+"</td></tr>";
        par.after(str);
        par = par.next();
      } else {
        par.find('td:last').append(data);
      }
      par.find('#md_tabs.nav.nav-tabs').each(function(i) {
        $(this).find('a:first').tab('show');
        $(this).parent().find('#new_line_edit_input').focus();
      });
    }
    var line = $(this);
    var tmp = line.parents('tr');
    var inline_comment = false;
    var par = null;

    if (tmp.hasClass('inline-comments')) {
      par = tmp;
    } else {
      par = tmp.next('tr.inline-comments');
    }

    if(par.length == 0) {
      par = tmp;
      inline_comment = true;
    }

    // Hide visible new comment form
    $('#open-comment.new_line_comment').parents('.inline-comments').each(function(i) {
      if($(this).find('.line-comments').length > 0) {
        $(this).find('#open-comment.new_line_comment').remove();
        $(this).find('.new_inline_comment.button').show();
      }
      else {
        $(this).remove();
      }
    });
    par.find('.new_inline_comment.button').hide();

    $.get(line.attr('href'), null, ProcessData);
    return false;
  });

  $(document).on('click', '.cancel_inline_comment.button', function() {
    var tr = $(this).parents('.inline-comments');
    if(tr.find('.line-comments').length > 0) {
      tr.find('#open-comment.new_line_comment').remove();
      tr.find('.new_inline_comment.button').show();
    }
    else {
      tr.remove();
    }
    return false;
  });
});


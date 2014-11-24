$(document).ready(function() {

  $('#search_user').on('keyup', function() {
    path = $('#search_user_path').attr('path');
    data = $(this).serialize();
    // dom = $('#manage_issue_users_list');
    dom = $('#assigned-popup .list');
    return search_items(path, data, dom);
  });

  $('.users-search-popup .header .icon-remove-circle').on('click', function() {
    $('.users-search-popup').hide();
  });

  $(document).on('click', '#assigned-container .icon-share', function() {
    $('#assigned-popup').show();
  });

  $(document).on('click', '#assigned-popup .people.selected', function() {
    var form = $('#assigned-popup .edit_assignee');
    var item = $(this);
    if (form.length == 0) {
      updateAssignedUser(item);
      return false;
    }
    $.ajax({
      type: 'PUT',
      url: form.attr("action"),
      data: $(this).find('input').serialize(),
      success: function(data){
                      updateAssignedUser(item);
                    },
      error: function(data){
                   alert('error'); // TODO remove
                }
     });
    return false;
  });

  $('.add_label.label').on('click', function() {
    $(this).addClass('selected').removeClass('add_label').addClass('remove_label');
    $(this).find('.labeltext').addClass('selected');
    var style = $(this).find('.flag').attr('style');
    $(this).find('.flag').fadeOut(0);
    $(this).find('.labeltext.selected').attr('style', style);
    var form_new = $('form.form.issue');
    var clone = $(this).clone();
    form_new.find('#flag-span').fadeOut(0);
    form_new.find('#issue_labels').append(clone);
    var labels = $('.manage_labels');
    labels.append($(this).find('#'+$(this).attr('id')));
  });

  $('.remove_label.label.selected').on('click', function() {
    var id = $(this).attr('id');
    $('.manage_labels, #active_labels').find('#'+id+'.label.selected.remove_label').remove();
    var form = $('.form.issue');
    if(form.find('.remove_label.label.selected').length == 1) {
      form.find('#flag-span').fadeIn(0);
    }
    var str = '.label.remove_label'+'#'+id;
    form.find(str).remove();
    var label = $(str);
    label.removeClass('selected').addClass('add_label').removeClass('remove_label');
    label.find('.labeltext.selected').attr('style', '').removeClass('selected');
    label.find('.flag').fadeIn(0);
    $('.manage_labels').find('#'+$(this).attr('id')).remove();
  });

  $('.issue_status.switch_issue_status').on('click', function () {
    var button = $(this);
    var status = (button.hasClass('switcher')) ? 'closed' : 'open';
    var form = $('#update_issue_status');
    form.find('#issue_status').attr('value', status);
    $.ajax({
      type: 'POST',
      url: form.attr("action"),
      data: form.serialize(),
      success: function(data){
                  if (status == "open") { button.addClass('switcher').removeClass("switcher-off"); }
                  else { button.removeClass('switcher').addClass("switcher-off"); }
                  $('#closed_issue_text').html(data);
                },
      error: function(data){
               alert('error') // TODO remove
             }
     });
    return false;
  });

  $('#edit_issue_content').on('click', function() {
    $('.edit_form.issue').fadeIn('fast');
    $(this).fadeOut('fast');
  });

  $('#cancel_edit_issue_content').on('click', function() {
    $('.edit_form.issue').fadeOut('fast');
    $('#edit_issue_content').fadeIn('fast');
  });

  $('.edit_form.issue').on('submit', function() {
    var form = $(this);
    form.parent().find('.flash').remove();
    $.ajax({
      type: 'POST',
      url: form.attr("action"),
      data: form.serialize(),
      success: function(data){
                  form.fadeOut('slow');
                  $('#edit_issue_content').fadeIn('slow');
                  $('h3.issue_title').html(form.find('#issue_title').attr('value'));
                  $('.fulltext.view.issue_body').html(data);
                },
      error: function(data){
               form.before(data.responseText);
             }
     });
    return false;
  });
});

function updateAssignedUser(item) {
  $('#assigned-popup').hide();
  var container = item.find('.container').clone();
  $('#assigned-container .user-container').empty().append(container.html()).append('<span class="icon-share"></span>');
}

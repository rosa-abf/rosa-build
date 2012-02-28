$(document).ready(function() {

  $("#closed-switcher").live('click', function() {
    if ($("#blue-switch-select").css("margin-left") != "130px") {
      $("#blue-switch-select").animate({"margin-left": "+=130px"}, "fast");
      $("#table1").fadeOut(0);
      $("#table2").fadeIn("slow");
      $('#issues_status').val('closed');
    }
    else {
      $("#blue-switch-select").animate({"margin-left": "-=130px"}, "fast");
      $("#table2").fadeOut(0);
      $("#table1").fadeIn("slow");
      $('#issues_status').val('open');
    }
    return send_index_tracker_request('GET');
  });

  $("#manage-labels").live('click', function () {
      var toggled = $(this).data('toggled');
      $(this).data('toggled', !toggled);
      if (!toggled) {
        $("#labels-stock").fadeOut(0);
        $("#labels-edit").fadeIn("slow");
      }
      else {
        $("#labels-edit").fadeOut(0);
        $("#labels-stock").fadeIn("slow");
      }
  });

  $("div.div-tracker-labels").live('click', function() {
    var flag = this.id;
    flag = flag.replace("label-","flag-");
    var bg = $("#"+flag).css("background-color");
    var checkbox = $(this).find(':checkbox');
    if ($(this).css("background-color") != bg) {
      $(this).css("background-color",bg);
      $(this).css("color","#FFFFFF");
      checkbox.attr('checked', 'checked');
    } else {
      $(this).css("background-color","rgb(247, 247, 247)");
      $(this).css("color","#565657");
      checkbox.removeAttr('checked');
    }
    return send_index_tracker_request('GET');
  });

  $("#myradio1").live('change', function(event) {
    return send_index_tracker_request('GET');
  });

  $('#search_issue').live('submit', function() {
    return send_index_tracker_request('GET', $(this).attr("action"), $(this).serialize());
  });

  $('#add_label').live('click', function() {
    return send_index_tracker_request('POST', $(this).attr("href"), $('#new_label').serialize());
  });

  $('.righter #update_label').live('click', function() {
    return send_index_tracker_request('POST', $(this).attr("href"), $(this).parents('#update_label').serialize());
  });

  $('.colors .choose').live('click', function() {
    var parent = $(this).parents('.colors');
    parent.find('.choose.selected').removeClass('selected');
    $(this).addClass('selected');
    parent.siblings('.lefter').find('#label_color').val($(this).attr('value'));
    return false;
  });

  $('.custom_color').live('click', function() {
    $(this).siblings('#label_color').toggle();
    return false;
  });

  $('article a.edit_label').live('click', function() {
    $(this).parents('.label.edit').siblings('.label.edit').find('.edit_label_form').hide();
    $(this).parents('.label.edit').find('.edit_label_form').toggle();
    return false;
  });

  $('.delete_label').live('click', function() {
    return send_index_tracker_request('POST', $(this).attr('href'));
  });

  function send_index_tracker_request(type_request, url, data) {
    data = data || '';
    var filter_form = $('#filter_issues');
    url = url || filter_form.attr("action");
    var label_form = $('#filter_labels');
    var status = 'status=' + $('#issues_status').attr('value');
    $.ajax({
      type: type_request,
      url: url,
      data: filter_form.serialize() + '&' + label_form.serialize() + '&' + status + '&' + data,
      success: function(data){
                 $('article').html(data);
                 $(".niceRadio").each(function() { changeRadioStart(jQuery(this)) });
               },
      error: function(data){
               alert('error') // TODO remove
             }
     });
    return false;
  };

  $('#search_user, #search_labels').live('submit', function() {
    var id = $(this).attr('id');
    if(id.indexOf('user') != -1) { // FIXME
      var which = 'users';
    }
    else if (id.indexOf('labels') != -1) {
      var which = 'labels';
    }
    $.ajax({
      type: 'GET',
      url: $(this).attr("action"),
      data: $(this).serialize(),
      success: function(data){
                  var tmp = $('#create_issue_'+ which +'_list');
                 $('#create_issue_'+ which +'_list').html(data);
               },
      error: function(data){
               alert('error') // TODO remove
             }
     });
    return false;
  });

  function remExecutor(form) {
    var el = form.find('.people.selected.remove_executor');
    var id = el.attr('id');
    $('#'+id+'.add_executor.people.selected').removeClass('select');
    el.remove();
  }

  $('.add_executor.people.selected').live('click', function() {
    var form = $('.form.issue');
    form.find('#people-span').fadeOut(0);
    remExecutor(form);
    form.find('#issue_executor').html($(this).clone().removeClass('add_executor').addClass('remove_executor'));
    $(this).addClass('select');
  });

  $('.remove_executor.people.selected').live('click', function() {
    var form = $('.form.issue');
    form.find('#people-span').fadeIn(0);
    remExecutor(form);
  });

  function remLabel(form, id) {
    var el = form.find('.label.remove_label'+'#'+id);
    var label = $('#'+id+'.remove_label.label.selected');
    label.find('.flag').fadeIn(0);
    label.find('.labeltext.selected').removeClass('selected').attr('style', '');
    label.fadeIn('slow');
    el.fadeOut('slow').remove();
  }

  $('.add_label.label').live('click', function() {
    $(this).addClass('selected').removeClass('add_label').addClass('remove_label');
    $(this).find('.labeltext').addClass('selected');
    var style = $(this).find('.flag').attr('style');
    $(this).find('.flag').fadeOut(0);
    $(this).find('.labeltext.selected').attr('style', style);
    var form = $('.form.issue');
    form.find('#flag-span').fadeOut(0);
    form.find('#issue_labels').append($(this).clone());
  });

  $('.remove_label.label.selected').live('click', function() {
    var form = $('.form.issue');
    if(form.find('.remove_label.label.selected').length == 1) {
      form.find('#flag-span').fadeIn(0);
    }
    var str = '.label.remove_label'+'#'+$(this).attr('id');
    form.find(str).remove();
    var label = $(str);
    label.removeClass('selected').addClass('add_label').removeClass('remove_label');
    label.find('.labeltext.selected').attr('style', '').removeClass('selected');
    label.find('.flag').fadeIn(0);

  });

  $('.issue_status.switch_issue_status').live('click', function () {
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

  $('#edit_issue_content').live('click', function() {
    $('.edit_form.issue').fadeIn('slow');
    $(this).fadeOut('slow');
  });

  $('.edit_form.issue').live('submit', function() {
    var form = $(this);
    $.ajax({
      type: 'POST',
      url: form.attr("action"),
      data: form.serialize(),
      success: function(data){
                  form.fadeOut('slow');
                  $('#edit_issue_content').fadeIn('slow');
                  $('h3.issue_title').html(form.find('#issue_title').attr('value'));
                  $('.fulltext.view.issue_body').html(form.find('#issue_body').attr('value'));
                },
      error: function(data){
               alert('error') // TODO remove
             }
     });
    return false;
  });

});

$(document).ready(function() {
  var locale = {};

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
    var form = $('#filter_issues');
    return send_request('GET', form.attr("action"));
  });

  function showEditLabels() {
    $("#labels-stock").fadeOut(0);
    $("#labels-edit").fadeIn("slow");
  };
  function hideEditLabels() {
    $("#labels-edit").fadeOut(0);
    $("#labels-stock").fadeIn("slow");
  };

  $("#manage-labels").live('click', function () {
      var toggled = $(this).data('toggled');
      $(this).data('toggled', !toggled);
      if (!toggled) {
          showEditLabels();
      }
      else {
          hideEditLabels();
      }
  });

  $("div.delete").click(function() {
  var div = "#label-"+this.id;
  $(div).fadeOut("slow");
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
    send_request('GET');
  });

  function showRow(elem) {
    if ($("#"+elem).css("display") == "none") {
      $("#"+elem).fadeIn("slow");
    } else {
      //$("#"+elem).fadeOut(0);
    }
  }

  function hideRow(elem) {
    if ($("#"+elem).css("display") != "none") {
      $("#"+elem).fadeOut("fast");
    } else {
      //$("#"+elem).fadeOut(0);
    }
  }

  $("#myradio1").live('change', function(event) {
    return send_request('GET', $('#filter_issues').attr("action"));
  });

  $('#search_issue').live('submit', function() {
    return send_request('GET', $(this).attr("action"), $(this).serialize());
  });

  $('#add_label').live('click', function() {
    return send_request('POST', $(this).attr("href"), $('#new_label').serialize());
  });

  $('.righter #update_label').live('click', function() {
    return send_request('POST', $(this).attr("href"), $(this).parents('#update_label').serialize());
  });

  $('.colors .choose').live('click', function() {
    var parent = $(this).parents('.colors');
    parent.find('.choose.selected').removeClass('selected');
    $(this).addClass('selected');
    parent.siblings('.lefter').find('#label_color').val($(this).attr('value'));
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
    return send_request('POST', $(this).attr('href'));
  });

  function send_request(type_request, url, data) {
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
               alert('error')
             }
     });
    return false;
  };

});

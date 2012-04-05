//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require autocomplete-rails
//= require vendor
//= require jquery.dataTables_ext
//= require_tree ./design
//= require_tree ./extra
//= require_self

function disableNotifierCbx(global_cbx) {
  if ($(global_cbx).attr('checked')) {
    $('.notify_cbx').removeAttr('disabled');
    $('.notify_cbx').each(function(i,el) { $(el).prev().removeAttr('disabled'); })
  } else {
    $('.notify_cbx').attr('disabled', 'disabled');
    $('.notify_cbx').each(function(i,el) { $(el).prev().attr('disabled', 'disabled'); })
  }
}

$(document).ready(function() {
  $('input.user_role_chbx').click(function() {
      var current = $(this);
      current.parent().find('input.user_role_chbx').each(function(i,el) {
          if ($(el).attr('id') != current.attr('id')) {
              $(el).removeAttr('checked');  
          }
      });
  });

  $('#settings_notifier_can_notify').click(function() {
      disableNotifierCbx($(this));
  });

  $('div.information > div.profile > a').live('click', function(e) {
      e.preventDefault();
  });

  $('.more_activities').live('click', function(){
    var button = $(this);
    $.ajax({
      type: 'GET',
      url: button.attr("href"),
      success: function(data){
                      button.fadeOut('slow').after(data);
                      button.remove();
                    }
     });
    return false;
  });

  $('.description-top .git_help').click(function() {
    $('#git_help_data').toggle();
    var desc = $('.description-top');

    if ($('#git_help_data').css('display') == 'none') {
      desc.css('height', '38px');
    } else {
      desc.css('height', '200px');
    }
  });

});

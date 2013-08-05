//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require autocomplete-rails
//= require vendor
//= require jquery.dataTables_ext
//= require_tree ./design
//= require_tree ./extra
//= require_tree ./lib

//= require underscore
//= require backbone
//= require backbone_rails_sync
//= require backbone_datalink
//= require backbone/rosa

//= require js-routes
// require angular
//= require unstable/angular
// require angular-resource
//= require unstable/angular-resource
//= require ng-rails-csrf
//= require angular-i18n
//= require_tree ./angularjs
//= require moment

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
  // setup all placeholders on page
  $('input[placeholder], textarea[placeholder]').placeholder();


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

  $('#description-top .git_help').click(function() {
    $('#git_help_data').toggle();
  });

  $(".toggle_btn").click(function() {
    var target = $( $(this).attr('data-target') );
    //target.toggle();
    if ( target.css('visibility') == 'hidden' ) {
      target.css('visibility', 'visible');
    } else {
      target.css('visibility', 'hidden');
    }
    return false;
  });

  window.CodeMirrorRun = function(code) {
    CodeMirror.runMode(code.innerHTML.replace(/&amp;/gi, '&').replace(/&lt;/gi, '<').replace(/&gt;/gi, '>'), code.className, code);
  }

  $('.md_and_cm code').each(function (code) { CodeMirrorRun(this); });
});

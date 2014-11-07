//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require js-routes

// require jquery.dataTables
// require jquery.dataTables_ext

//= require autocomplete-rails
// require extra/autocomplete-form

//= require bootstrap-sprockets

//= require angular
//= require angular-sanitize
//= require angular-ui-bootstrap-tpls
//= require ui-codemirror
//= require angular-i18n
//= require angularjs/locales

//= require angular-resource
//= require ng-rails-csrf
//= require angular-cookies
//= require soundmanager2-nodebug-jsmin

//= require angular-rails-templates

//= require moment
//= require angularjs/angular-moment

//= require_tree ./angular-new
//= require loading-bar

//= require underscore

//= require zeroclipboard

//= require_self

function setCookie (name, value, expires, path, domain, secure) {
  document.cookie = name + "=" + escape(value) +
    ((expires) ? "; expires=" + expires : "") +
    ((path) ? "; path=" + path : "") +
    ((domain) ? "; domain=" + domain : "") +
    ((secure) ? "; secure" : "");
}

$(document).ready(function() {
  $('.notify.alert button.close').click(function () {
    var exdate=new Date();
    exdate.setDate(exdate.getDate() + 365);
    var expires="expires="+exdate.toUTCString();
    setCookie("flash_notify_hash", FLASH_HASH_ID, expires);
  });

  var clip = new ZeroClipboard($("#clipboard_copy_button"));

  $('.datetime_moment').each(function() {
    var mtime = moment($(this).attr('origin_datetime'), 'X').format('YYYY-MM-DD HH:mm:ss UTC');
    $(this).attr('title', mtime);
  });

  window.updateTime = function () {
    $('.datetime_moment').each(function() {
      var time = moment($(this).attr('origin_datetime'), 'X');
      $(this).html(time.format('D MMM YYYY, HH:mm') + ' (' + time.fromNow() + ')');
    });
  };

  updateTime();
  setInterval( updateTime, 15000 );

  // TODO refactoring
  $('#branch_selector').change(function() {
    var form = $('form#branch_changer');
    form.attr('action', $(this).val());
    form.submit();
  });

  $('#create_fork').click(function () {
    $(this).button('loading');
  });

});

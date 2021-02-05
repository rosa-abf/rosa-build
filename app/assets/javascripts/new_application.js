//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require js-routes

//= require bootstrap-sprockets

//= require bundle/angular.min
//= require bundle/angular-sanitize.min
//= require bundle/angular-ui-bootstrap-tpls.min
//= require ui-codemirror
//= require lib/angular-i18n

//= require bundle/angular-resource.min
//= require lib/ng-rails-csrf
//= require bundle/angular-cookies.min

//= require angular-rails-templates

//= require bundle/moment.min

//= require_tree ./angularjs
//= require loading-bar

//= require bundle/underscore.min

//= require notifyjs
//= require notifyjs/styles/bootstrap/notify-bootstrap

//= require lib/Chart
//= require lib/bootstrap-typeahead
//= require lib/custom-bootstrap-typeahead

//= require extra/highlight
//= require extra/pull
//= require extra/scroller
//= require extra/fork
//= require extra/diff_chevrons
//= require extra/diff

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

  $('.datetime_moment').each(function() {
    var mtime = moment($(this).attr('origin_datetime'), 'YYYY-MM-DD HH:mm Z');
    $(this).attr('title', mtime.utc().format('YYYY-MM-DD HH:mm:ss UTC'));
  });

  window.updateTime = function () {
    $('.datetime_moment').each(function() {
      var time = moment($(this).attr('origin_datetime'), 'YYYY-MM-DD HH:mm Z');
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

  $('[data-toggle="tooltip"]').tooltip();
});

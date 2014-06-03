//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require js-routes

// Loads all Bootstrap javascripts
//= require bootstrap

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

//= require moment
//= require angularjs/angular-moment

//= require_tree ./angular-new
//= require loading-bar

//= require underscore

//= require_self

function setCookie (name, value, expires, path, domain, secure) {
  document.cookie = name + "=" + escape(value) +
    ((expires) ? "; expires=" + expires : "") +
    ((path) ? "; path=" + path : "") +
    ((domain) ? "; domain=" + domain : "") +
    ((secure) ? "; secure" : "");
}

$(document).ready(function() {
  $('.alert button.close').click(function () {
    var exdate=new Date();
    exdate.setDate(exdate.getDate() + 365);
    var expires="expires="+exdate.toUTCString();
    setCookie("flash_notify_hash", FLASH_HASH_ID, expires);
  });
});

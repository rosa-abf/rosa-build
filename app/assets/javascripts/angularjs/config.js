var RosaABF = angular.module('RosaABF', ['ngResource', 'ng-rails-csrf', 'angular-i18n']);

var DateTimeFormatter = function() {

  var UtcFormatter = function(api_time) {
    return moment.utc(api_time * 1000).format('YYYY-MM-DD HH:mm:ss UTC');
  }

  return {
    utc : UtcFormatter
  }
}
RosaABF.factory("DateTimeFormatter", DateTimeFormatter);

var LocalesHelper = function($locale) {
  var locales = {
    'ru' : 'ru-ru',
    'en' : 'en-us'
  }
  return {
    setLocale: function(locale) {
      $locale.id = locales[locale];
    }
  }
}
RosaABF.factory("LocalesHelper", ['$locale', LocalesHelper]);
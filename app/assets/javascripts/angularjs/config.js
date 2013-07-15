var RosaABF = angular.module('RosaABF', ['ngResource', 'ng-rails-csrf']);

var DateTimeFormatter = function() {

  var UtcFormatter = function(api_time) {
  	return moment.utc(api_time * 1000).format('YYYY-MM-DD HH:mm:ss UTC');
  }

  return {
    utc : UtcFormatter
  }
}

RosaABF.factory("DateTimeFormatter", DateTimeFormatter);
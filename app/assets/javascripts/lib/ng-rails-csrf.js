angular.module('ng-rails-csrf', []).config(['$httpProvider', function($httpProvider) {
  var el = document.querySelector('meta[name="csrf-token"]');
  if (el) {
      el = el.getAttribute('content');
  }
  if (!el) {
    return;
  }
  var headers = $httpProvider.defaults.headers.common;
  headers['X-CSRF-TOKEN'] = el;
  headers['X-Requested-With'] = 'XMLHttpRequest';
}]);
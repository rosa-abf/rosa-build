RosaABF.controller('RosaABFController', ['$scope', 'LocalesHelper', function($scope, LocalesHelper) {

  $scope.init = function(locale) {
  	LocalesHelper.setLocale(locale);
    moment.lang(locale);
  }
}]);

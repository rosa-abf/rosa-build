RosaABF.controller('PlatformsCtrl', ['$scope', '$http', '$timeout', function($scope, $http, $timeout) {
  $scope.total_items = null;
  $scope.page        = null;
  $scope.platforms   = null;

  $scope.init = function(total_items, page) {
    $scope.total_items = total_items;
    $scope.page        = page;
  };

  $scope.getPlatforms = function() {
    $http.get(Routes.platforms_path({format: 'json', page: $scope.page})).then(function(res) {
      $scope.page        = res.data.page;
      $scope.total_items = parseInt(res.data.platforms_count, 10);
      $scope.platforms   = res.data.platforms;
    });
  };

  $scope.goToPage = function(page) {
    $scope.page = page;
    $scope.getPlatforms();
  };

  $scope.getPlatforms();
}]);

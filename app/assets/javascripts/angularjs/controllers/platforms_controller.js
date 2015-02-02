RosaABF.controller('PlatformsCtrl', ['$scope', '$http', function($scope, $http) {
  $scope.total_items = null;
  $scope.page        = null;
  $scope.platforms   = null;

  $scope.getPlatforms = function() {
    $http.get(Routes.platforms_path({format: 'json', page: $scope.page})).then(function(res) {
      $scope.page        = res.data.page;
      $scope.total_items = res.data.platforms_count;
      $scope.platforms   = res.data.platforms;
    });
  };

  $scope.goToPage = function(page) {
    $scope.page = page;
    $scope.getPlatforms();
  };

  $scope.getPlatforms();
}]);

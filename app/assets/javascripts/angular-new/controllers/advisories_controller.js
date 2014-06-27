RosaABF.controller('AdvisoryCtrl', ['$scope', '$http', function($scope, $http) {
  $scope.total_items = null;
  $scope.page        = null;
  $scope.advisories  = null;
  $scope.q           = null;

  $scope.init = function(total_items, page, q) {
    $scope.total_items = total_items;
    $scope.page        = page;
    $scope.q           = q;
  };

  $scope.getAdvisories = function() {
    $http.get(Routes.advisories_path({format: 'json', page: $scope.page, q: $scope.q})).then(function(res) {
      $scope.page        = res.data.page;
      $scope.total_items = parseInt(res.data.advisories_count, 10);
      $scope.advisories  = res.data.advisories;
    });
  };

  $scope.goToPage = function(page) {
    $scope.page = page;
    $scope.getAdvisories();
  };

  $scope.getAdvisories();
}]);

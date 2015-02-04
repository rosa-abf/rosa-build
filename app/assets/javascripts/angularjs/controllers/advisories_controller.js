RosaABF.controller('AdvisoryCtrl', ['$scope', '$http', function($scope, $http) {
  $scope.total_items = null;
  $scope.page        = null;
  $scope.advisories  = null;
  $scope.q           = null;

  $scope.init = function(q) {
    $scope.q           = q;
  };

  $scope.getAdvisories = function() {
    $http.get(Routes.advisories_path({format: 'json', page: $scope.page, q: $scope.q})).then(function(res) {
      $scope.page        = res.data.page;
      $scope.total_items = res.data.advisories_count;
      $scope.advisories  = res.data.advisories;
    });
  };

  $scope.goToPage = function(page) {
    $scope.page = page;
    $scope.getAdvisories();
  };

  $scope.getAdvisories();
}]);

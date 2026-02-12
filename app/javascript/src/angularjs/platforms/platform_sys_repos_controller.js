RosaABF.controller('PlatformSysReposController', ['$scope', '$http', function($scope, $http) {

  $scope.init = function(platform_id) {
    var path = Routes.platform_path(platform_id);
    $http.get(path, { format: 'json' }).then(function(res) {
      $scope.list = res.data.list;
      $scope.platforms = res.data.platforms;
      $scope.arches = res.data.arches;

      $scope.platform = res.data.platforms[0];
      $scope.arch = res.data.arches[0];
      $scope.updateCommand();
    });
  };

  $scope.updateCommand = function() {
    if ($scope.platform && $scope.arch) {
      $scope.command = $scope.list[$scope.platform][$scope.arch];
    } else {
      $scope.command = '';
    }
  };

  $scope.selectAll = function($event) {
    var target = $($event.currentTarget);
    target.select();
    return false;
  };

}]);

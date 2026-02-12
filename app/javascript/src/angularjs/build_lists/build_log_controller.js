RosaABF.controller('BuildLogController', ['$scope', '$http', '$timeout', ($scope, $http, $timeout) =>{

  $scope.path           = null;
  $scope.log            = null;
  $scope.build_started  = true;

  $scope.init = (path)=>{
    $scope.path = path;
    $scope.getLog();
  }

  $scope.getLog = ()=>{
    if (!$scope.build_started)
      return;

    if ($('.build-log').is(':visible')) {
      $http.get($scope.path, { timeout: 30000 }).then((res)=>{
        $scope.log = res.data.log;
        $scope.build_started = res.data.building;
      }).catch(()=>{
        $scope.log = null;
      }).finally(()=>{
        $timeout($scope.getLog, 10000);
      });
    }
    return true
  }
}]);

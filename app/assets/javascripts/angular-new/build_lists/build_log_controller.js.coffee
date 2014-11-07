RosaABF.controller 'BuildLogController', ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $scope.path           = null
  $scope.log            = null
  $scope.build_started  = true

  $scope.init = (path) ->
    $scope.path = path
    $scope.getLog()

  $scope.getLog = ->
    return unless $scope.build_started

    if $('.build-log').is(':visible')
      $http.get($scope.path).success (res) ->
        $scope.log            = res.log
        $scope.build_started  = res.building
      .error ->
        $scope.log            = null

    $timeout($scope.getLog, 10000);

]
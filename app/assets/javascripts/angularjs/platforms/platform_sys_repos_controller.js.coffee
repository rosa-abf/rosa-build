RosaABF.controller 'PlatformSysReposController', ['$scope', '$http', ($scope, $http) ->

  $scope.init = (platform_id) ->
    path = Routes.platform_path platform_id
    $http.get(path, { format: 'json' }).success (res) ->
      $scope.list       = res.list
      $scope.platforms  = res.platforms
      $scope.arches     = res.arches

      $scope.platform   = res.platforms[0]
      $scope.arch       = res.arches[0]
      $scope.updateCommand()

  $scope.updateCommand = ->
    if $scope.platform && $scope.arch
      $scope.command = $scope.list[$scope.platform][$scope.arch]
    else
      $scope.command = ''


  $scope.selectAll = ($event) ->
    target = $($event.currentTarget)
    target.select()
    false

]
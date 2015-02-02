RosaABF.controller 'AutomaticMetadataRegenerationController', ['$scope', '$http', ($scope, $http) ->

  # See: Platfrom::AUTOMATIC_METADATA_REGENERATIONS
  $scope.items =
    day:  'platform.automatic_metadata_regeneration.day'
    week: 'platform.automatic_metadata_regeneration.week'

  $scope.platform_id = null

  $scope.update = ->
    path    = Routes.platform_path($scope.platform_id)
    params  = 
      platform:
        automatic_metadata_regeneration: $scope.amr
      format: 'json'
    $http.put(path,params)

]
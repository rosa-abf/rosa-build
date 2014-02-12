RosaABF.controller('AutomaticMetadataRegenerationController', ['$scope', '$http', function($scope, $http) {

  // See: Platfrom::AUTOMATIC_METADATA_REGENERATIONS
  $scope.items = {
    'day': 'platform.automatic_metadata_regeneration.day',
    'week': 'platform.automatic_metadata_regeneration.week'
  };
  $scope.platform_id = null;

  $scope.update = function() {
    $http.put(
      Routes.platform_path($scope.platform_id),
      {platform: {automatic_metadata_regeneration: $scope.amr}, format: 'json'}
    );
  }  

}]);
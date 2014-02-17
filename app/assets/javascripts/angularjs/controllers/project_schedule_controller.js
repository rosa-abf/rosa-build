RosaABF.controller('ProjectScheduleController', ['$scope', '$http', function($scope, $http) {

  // See: Platfrom::AUTOMATIC_METADATA_REGENERATIONS
  // $scope.items = {
  //   'day': 'platform.automatic_metadata_regeneration.day',
  //   'week': 'platform.automatic_metadata_regeneration.week'
  // };
  $scope.project_id = null;

  $scope.update = function() {
    $http.put(
      Routes.project_path($scope.platform_id),
      {project: {autostart_status: $scope.autostart_status}, format: 'json'}
    );
  }  

}]);
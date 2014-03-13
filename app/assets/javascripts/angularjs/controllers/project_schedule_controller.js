RosaABF.controller('ProjectScheduleController', ['$scope', '$http', function($scope, $http) {

  // See: Modules::Models::Autostart::AUTOSTART_STATUSES
  $scope.statuses = {
    '0': 'autostart_statuses.0',
    '1': 'autostart_statuses.1',
    '2': 'autostart_statuses.2'
  };
  $scope.items    = [];

  $scope.updateStatus = function() {
    $http.put(
      Routes.project_path($scope.name_with_owner),
      {project: {autostart_status: $scope.autostart_status}, format: 'json'}
    );
  }

  $scope.updateSchedule = function(obj) {
    $http.put(
      Routes.project_schedule_path($scope.name_with_owner),
      {enabled: obj.enabled, auto_publish: obj.auto_publish, repository_id: obj.repository_id, format: 'json'}
    );
  }
}]);

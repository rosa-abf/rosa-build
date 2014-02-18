RosaABF.controller('ProjectScheduleController', ['$scope', '$http', function($scope, $http) {

  // See: Modules::Models::Autostart::AUTOSTART_STATUSES
  $scope.statuses = {
    '0': 'autostart_statuses.0',
    '1': 'autostart_statuses.1',
    '2': 'autostart_statuses.2'
  };
  $scope.project = null;
  $scope.owner   = null;

  $scope.items = [];


  $scope.init = function(name_with_owner) {
    var arr = name_with_owner.split('/');
    $scope.owner    = arr[0];
    $scope.project  = arr[1];
  }

  $scope.updateStatus = function() {
    $http.put(
      Routes.project_path($scope.owner, $scope.project),
      {project: {autostart_status: $scope.autostart_status}, format: 'json'}
    );
  }

  $scope.updateSchedule = function(obj) {
    $http.put(
      Routes.project_schedule_path($scope.owner, $scope.project),
      {enabled: obj.enabled, auto_publish: obj.auto_publish, repository_id: obj.repository_id, format: 'json'}
    );
  }


}]);
RosaABF.controller('ProjectsController', ['$scope', 'Projects', function($scope, Projects) {

  $scope.projects = Projects.query();
  $scope.public = true;
}]);

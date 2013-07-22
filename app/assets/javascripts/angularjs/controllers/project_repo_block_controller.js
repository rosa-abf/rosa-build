RosaABF.controller('ProjectRepoBlockController', ['$scope', 'ApiProject', function($scope, ApiProject) {

  $scope.singleton = ApiProject.singleton;

  $scope.init = function(branches) {
    $scope.singleton.project.branches_count = branches;
  }

}]);
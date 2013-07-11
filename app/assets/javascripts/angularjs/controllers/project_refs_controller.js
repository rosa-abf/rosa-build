RosaABF.controller('ProjectRefsController', function($scope, $http, $location, ApiProject) {

  $scope.branches = [];
  $scope.tags     = [];
  $scope.project_id = null;
  $scope.current_ref = null;

  $scope.init = function(project_id, ref) {
    $scope.project_id = project_id;
    $scope.current_ref = ref;
    ApiProject.project($scope.project_id, function(result){
      $scope.project = result;
    });
    $scope.getRefs();
  }

  $scope.getRefs = function() {
    //returns [ProjectRef, ProjectRef, ...]
    ApiProject.refs($scope.project_id, function(results){
      $scope.tags = [];
      $scope.branches = [];
      _.each(results, function(result){
        if (result.isTag) {
          if (result.ref == $scope.current_ref) {
            $scope.tags.unshift(result);
          } else {
            $scope.tags.push(result);
          }
        } else {
          if (result.ref == $scope.current_ref) {
            $scope.branches.unshift(result);
          } else {
            $scope.branches.push(result);
          }
        }
      });
    });
  };

  $scope.destroy = function(branch) {
    $http.delete(branch.delete_path($scope.project)).success(function(data) {
      $scope.getRefs();
    });
  }

});
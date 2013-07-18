RosaABF.controller('ProjectRefsController', ['$scope', '$http', 'ApiProject', function($scope, $http, ApiProject) {

  $scope.branches = [];
  $scope.tags     = [];

  $scope.project_id       = null;
  $scope.current_ref      = null;
  $scope.project_resource = null;

  $scope.init = function(project_id, ref) {
    $scope.project_id = project_id;
    $scope.current_ref = ref;

    $scope.project_resource = ApiProject.resource.get({id: $scope.project_id}, function(results) {
      $scope.project = new Project(results.project);
      $scope.getRefs();
    });

  }

  $scope.getRefs = function() {

    $scope.project_resource.$refs({id: $scope.project_id}, function(results) {
      $scope.tags = [];
      $scope.branches = [];
      _.each(results.refs_list, function(ref){
        var result = new ProjectRef(ref);
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

  }

  $scope.destroy = function(branch) {
    $scope.project_resource.$delete_branch(
      {owner: $scope.project.owner.uname, project: $scope.project.name, ref: branch.ref},
      function() { // on success
        var i = $scope.branches.indexOf(branch);
        if(i != -1) { $scope.branches.splice(i, 1); }
      }, function () { // on error
        $scope.getRefs();
      }
    );
  }

}]);
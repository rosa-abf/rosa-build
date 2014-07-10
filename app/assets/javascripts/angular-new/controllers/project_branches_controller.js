RosaABF.controller('ProjectBranchesController', ['$scope', '$http', 'ApiProject', function($scope, $http, ApiProject) {

  $scope.singleton  = ApiProject.singleton;
  $scope.branches   = [];

  $scope.current_ref      = null;
  $scope.project_resource = null;

  $scope.init = function(owner_uname, project_name, ref) {
    $scope.current_ref = ref;

    $scope.project_resource = ApiProject.resource.get(
      {owner: owner_uname, project: project_name},
      function(results) {
        $scope.project = new Project(results.project);
        $scope.getBranches();
      }
    );

  }

  $scope.getBranches = function() {

    $scope.project_resource.$branches(
      {owner: $scope.project.owner.uname, project: $scope.project.name},
      function(results) {
        $scope.branches = [];
        _.each(results.refs_list, function(ref){
          var result = new ProjectRef(ref);
          if (result.ref == $scope.current_ref) {
            $scope.branches.unshift(result);
          } else {
            $scope.branches.push(result);
          }
        });
        $scope.updateBranchesCount();
      }
    );

  }

  $scope.updateBranchesCount = function() {
    $scope.singleton.project.branches_count = $scope.branches.length;
  }

  $scope.create = function(branch) {
    branch.ui_container = false;
    $scope.project_resource.$create_branch(
      {
        owner:    $scope.project.owner.uname,
        project:  $scope.project.name,
        from_ref: branch.ref,
        new_ref:  branch.new_ref
      }, function() { // on success
        $scope.getBranches();
      }, function () { // on error
        $scope.getBranches();
      }
    );
  }

  $scope.destroy = function(branch) {
    $scope.project_resource.$delete_branch(
      {owner: $scope.project.owner.uname, project: $scope.project.name, ref: branch.ref},
      function() { // on success
        var i = $scope.branches.indexOf(branch);
        if(i != -1) { $scope.branches.splice(i, 1); }

        $scope.updateBranchesCount();
        // Removes branch from "Current branch/tag:" select box
        $('#branch_selector option').filter(function() {
          return this.value.match('.*\/branches\/' + branch.ref + '$');
        }).remove();
      }, function () { // on error
        $scope.getBranches();
      }
    );
  }

}]);
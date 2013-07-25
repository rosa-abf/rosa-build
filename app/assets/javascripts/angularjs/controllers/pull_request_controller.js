RosaABF.controller('PullRequestController',['$scope', '$http', 'ApiPullRequest', 'ApiProject', 'DateTimeFormatter', function($scope, $http, ApiPullRequest, ApiProject, DateTimeFormatter) {

  $scope.project_resource = null;

  $scope.pull_params      = null;
  $scope.pull             = null;
  $scope.pull_resource    = null;

  $scope.merged_at  = null;
  $scope.closed_at  = null;
  $scope.branch     = null;

  $scope.can_delete_branch  = false;

  $scope.init = function(owner_uname, project_name, serial_id) {
    $scope.pull_params = {
      owner:      owner_uname,
      project:    project_name,
      serial_id:  serial_id
    };
    $scope.getPullRequest();
  }

  $scope.getPullRequest = function() {
    $scope.pull_resource = ApiPullRequest.resource.get($scope.pull_params, function(results) {
      $scope.pull = results.pull_request;
      if ($scope.pull.merged_at) { $scope.merged_at = DateTimeFormatter.utc($scope.pull.merged_at); }
      if ($scope.pull.closed_at) { $scope.closed_at = DateTimeFormatter.utc($scope.pull.closed_at); }
    });
  }

  // @param [from_ref] - sets only at first time
  $scope.getBranch = function(from_ref) {
    if (!$scope.project_resource) {
      $scope.project_resource = ApiProject.resource.get($scope.pull_params);
    }
    // Fix: at first load
    // Cannot read property 'from_ref' of null
    if (!from_ref) { from_ref = $scope.pull.from_ref.ref; }
    $scope.project_resource.$branches($scope.pull_params, function(results) {
      var branch = null;
      _.each(results.refs_list, function(b){
        if (b.ref == from_ref) {
          branch = new ProjectRef(b);
          return true;
        }
      });
      $scope.branch = branch;
    });
  }

  $scope.reopen = function() {
    $scope.pull_resource.$update({pull_request_action: 'reopen'}, function() {
      $scope.getPullRequest();
    });
  }

  $scope.close = function() {
    $scope.pull_resource.$update({pull_request_action: 'close'}, function() {
      $scope.getPullRequest();
    });
  }

  $scope.merge = function() {
    $scope.pull_resource.$merge(function() {
      $scope.getPullRequest();
    });
  }

  $scope.deleteBranch = function() {
    $scope.project_resource.$delete_branch($scope.branch_params(),
      function() { $scope.branch = null;  }, // success
      function() { $scope.getBranch();    }  // error
    );
  }

  $scope.restoreBranch = function() {
    $scope.project_resource.$restore_branch($scope.branch_params(),
      function() { $scope.getBranch(); }, // success
      function() { $scope.getBranch(); }  // error
    );
  }

  $scope.branch_params = function() {
    return {
      owner:    $scope.pull_params.owner,
      project:  $scope.pull_params.project,
      ref:      $scope.pull.from_ref.ref,
      sha:      $scope.pull.from_ref.sha
    }
  }

}]);
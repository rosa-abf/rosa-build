RosaABF.controller('PullRequestController', function($scope, $http, ApiPullRequest, ApiProject) {

  $scope.project_id = null;
  $scope.serial_id  = null;
  $scope.pull       = null;
  $scope.pull_request = null;

  $scope.merged_at  = null;
  $scope.closed_at  = null;
  $scope.branch     = null;

  $scope.can_delete_branch  = false;
  $scope.check_branch       = false;

  $scope.init = function(project_id, serial_id) {
    $scope.project_id = project_id;
    $scope.serial_id  = serial_id;
    $scope.getPullRequest();
  }

  $scope.getPullRequest = function() {
    $scope.pull_request = ApiPullRequest.resource.get(
      {project_id: $scope.project_id, serial_id: $scope.serial_id},
      function(results) {
        $scope.pull = results.pull_request;
        if ($scope.pull.merged_at) { $scope.merged_at = new Date($scope.pull.merged_at * 1000).toUTCString(); }
        if ($scope.pull.closed_at) { $scope.closed_at = new Date($scope.pull.closed_at * 1000).toUTCString(); }
        if ($scope.check_branch && ($scope.pull.status == 'closed' || $scope.pull.status == 'merged')) { $scope.getBranch(); }
      }
    );
  }

  $scope.getBranch = function() {
    //returns [ProjectRef, ProjectRef, ...]
    ApiProject.refs($scope.project_id, function(results){
      _.each(results, function(result){
        if (!result.isTag && result.ref == $scope.pull.from_ref.ref) {
          $scope.can_delete_branch = result.object.sha == $scope.pull.from_ref.sha;
          $scope.branch = true;
          return true;
        }
      });
    });
  }

  $scope.reopen = function() {
    $scope.pull.status = 'reopen';
    $scope.pull_request.$update(function() {
      $scope.getPullRequest();
    });
  }

  $scope.close = function() {
    $scope.pull.status = 'close';
    $scope.pull_request.$update(function() {
      $scope.getPullRequest();
    });
  }

  $scope.merge = function() {
    $scope.pull_request.$merge(function() {
      $scope.getPullRequest();
    });
  }

  $scope.deleteBranch = function() {
    $http.delete($scope.branch_path())
         .success(function(data) { $scope.branch = false; });
  }

  $scope.restoreBranch = function() {
    $http.put($scope.branch_path(), {sha: $scope.pull.from_ref.sha})
         .success(function(data) { $scope.branch = true; });
  }

  $scope.branch_path = function() {
    return '/' + $scope.pull.from_ref.project.fullname + '/branches/' + $scope.pull.from_ref.ref;
  }

});
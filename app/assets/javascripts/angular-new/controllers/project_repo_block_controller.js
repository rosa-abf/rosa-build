RosaABF.controller('ProjectRepoBlockController', ['$scope', 'ApiProject', function($scope, ApiProject) {

  $scope.clone_url             = null;
  $scope.singleton             = ApiProject.singleton;
  $scope.clone_url_protocol    = 'ssh';
  $scope.is_collapsed_git_help = true;

  $scope.init = function(clone_url, branches) {
    $scope.clone_url = clone_url;
    $scope.singleton.project.branches_count = branches;
  }

  // TODO refactoring
  $scope.select_branch = function() {
    $form = $('form#branch_changer');
    $form.attr('action', $scope.branch);
    $form.submit();
  };

}]);
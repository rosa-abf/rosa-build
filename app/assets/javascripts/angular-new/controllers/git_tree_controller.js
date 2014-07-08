RosaABF.controller('GitTreeCtrl', ['$scope', '$http', function($scope, $http) {
  $scope.project   = null;
  $scope.treeish   = null;
  $scope.path      = null;
  $scope.root_path = null;
  $scope.tree      = null;

  $scope.init = function(project, treeish, path, root_path) {
    $scope.project   = project;
    $scope.treeish   = treeish;
    $scope.path      = path;
    $scope.path_path = root_path;
    $scope.getTree();
  };

  $scope.getTree = function($event, path) {
    if(path) { $scope.path = path; }
    if($scope.path) {
      var treeish = $scope.treeish+'/'+$scope.path;
    }
    else {
      var treeish = $scope.treeish;
    }
    $http.get(Routes.tree_path($scope.project, treeish, {format: 'json'})).then(function(res) {
      $scope.path            = res.data.path;
      $scope.root_path       = res.data.root_path;
      $scope.tree            = res.data.tree;
      $scope.path_breadcrumb = res.data.tree_breadcrumb;
    });

    if($event) {
      $event.preventDefault();
    }
  };
}]);

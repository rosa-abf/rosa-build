RosaABF.controller('GitTreeCtrl', ['$scope', '$http', function($scope, $http) {
  $scope.project    = null;
  $scope.treeish    = null;
  $scope.path       = null;
  $scope.root_path  = null;
  $scope.tree       = null;
  $scope.breadcrumb = null;
  $scope.processing = false;

  $scope.init = function(project, treeish, path, root_path) {
    $scope.project   = project;
    $scope.treeish   = treeish;
    $scope.path      = path;
    $scope.path_path = root_path;
    $scope.getTree();
  };

  $scope.getTree = function($event, path, more) {
    $scope.processing = true;
    more = typeof more !== 'undefined' ? more : false;

    if(path) { $scope.path = path; }
    if($scope.path) {
      var treeish = $scope.treeish+'/'+$scope.path;
    }
    else {
      var treeish = $scope.treeish;
    }
    var params = {format: 'json'};
    if(more) {
      params.page = $scope.next_page;
    }

    $http.get(Routes.tree_path($scope.project, treeish, params)).then(function(res) {
      $scope.path       = res.data.path;
      $scope.root_path  = res.data.root_path;
      $scope.breadcrumb = res.data.breadcrumb;
      $scope.next_page  = res.data.next_page;
      if(more) {
        $scope.tree.push.apply($scope.tree, res.data.tree);
      }
      else {
        $scope.tree     = res.data.tree;
      }
      $scope.processing = false;
    });

    if($event) {
      $event.preventDefault();
    }
  };
}]);

RosaABF.controller('GitTreeCtrl', ['$scope', '$http', '$location', function($scope, $http, $location) {
  $scope.project    = null;
  $scope.treeish    = null;
  $scope.root_path  = null;
  $scope.tree       = null;
  $scope.breadcrumb = null;
  $scope.processing = false;

  $scope.init = function(project, treeish, path, root_path) {
    $scope.project   = project;
    $scope.treeish   = treeish;
    $scope.root_path = root_path;
    $scope.path      = path;
    //$scope.getTree();
  };

  $scope.refresh = function(more) {
    $scope.processing = true;

    var params = { format: 'json', path: $scope.path };

    if(more) {
      params.page = $scope.next_page;
    }

    $http.get(Routes.tree_path($scope.project, $scope.treeish, params)).then(function(res) {
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
  };

  $scope.$on('$locationChangeSuccess', function(event) {
    $scope.path = $location.search()['path'];
    $scope.refresh();
  });

  $scope.getTree = function($event, path, more) {
    if($scope.processing && $event) {
      return $event.preventDefault();
    }

    more = typeof more !== 'undefined' ? more : false;
    if(path && path !== '') { $scope.path = path; }
    else { $scope.path = null; }

    if(more) {
      $scope.refresh(more);
    }
    else {
      $location.search('path', $scope.path);
    }

    if($event) {
      $event.preventDefault();
    }
  };
}]);

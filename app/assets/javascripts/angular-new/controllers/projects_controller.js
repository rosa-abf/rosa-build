RosaABF.controller('ProjectsCtrl', ['$scope', '$http', function($scope, $http) {
  $scope.total_items   = null;
  $scope.page          = null;
  $scope.projects      = null;
  $scope.filter_users  = [];
  $scope.filter_groups = [];
  // remove_user_project_path(project), method: :delete

  $scope.init = function(total_items, page) {
    $scope.total_items = total_items;
    $scope.page        = page;
  };

  $scope.getProjects = function() {
    var params = { format: 'json', page: $scope.page, search: $scope.search,
                   users: $scope.filter_users, groups: $scope.filter_groups };
    $http.get(Routes.projects_path(params)).then(function(res) {
      $scope.page        = res.data.page;
      $scope.total_items = res.data.projects_count;
      $scope.projects    = res.data.projects;
    });
  };

  $scope.goToPage = function(page) {
    $scope.page = page;
    $scope.getProjects();
  };

  $scope.leave_project = function(project) {
    project.can_leave_project = false;
    var path = Routes.remove_user_project_path(project.name_with_owner, {format: 'json'});
    $http.delete(path).success(function(res){
      //$scope.getProjects();
      // Find and remove item from an array
      var i = $scope.projects.indexOf(project);
      if(i != -1) {
        $scope.projects.splice(i, 1);
      }
    }).error(function() {
      $scope.getProjects();
    });
  };

  $scope.change_user_filter = function(user_id) {
    var position = $.inArray(user_id, $scope.filter_users);
    var filter   = 'user_filter_'+user_id+'_class';
    if( ~position ) {
      $scope.filter_users.splice(position, 1);
      $scope[filter] = false;
    }
    else {
      $scope.filter_users.push(user_id);
      $scope[filter] = true;
    }
    $scope.getProjects();
  };

  $scope.change_group_filter = function(group_id) {
    var position = $.inArray(group_id, $scope.filter_groups);
    var filter   = 'group_filter_'+group_id+'_class';
    if( ~position ) {
      $scope.filter_groups.splice(position, 1);
      $scope[filter] = false;
    }
    else {
      $scope.filter_groups.push(group_id);
      $scope[filter] = true;
    }
    $scope.getProjects();
  };

  $scope.getProjects();
}]);

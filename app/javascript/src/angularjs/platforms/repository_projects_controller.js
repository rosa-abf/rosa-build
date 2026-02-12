RosaABF.controller('RepositoryProjectsController', ['$scope', '$http', '$location', 'confirmMessage', function($scope, $http, $location, confirmMessage) {

  $scope.added = $('#added').val();
  $scope.platform_id = $('#platform_id').val();
  $scope.repository_id = $('#repository_id').val();
  $scope.processing = true;
  $scope.projects = [];
  $scope.total_items = null;

  // Fixes: redirect to page after form submit
  $("#search_projects_form").on('submit', function() {
    return false;
  });

  $scope.refresh = function() {
    $scope.processing = true;

    var params = {
      added: $scope.added,
      owner_name: $('#project_owner').val(),
      project_name: $('#project_name').val(),
      page: $('#page').val(),
      format: 'json'
    };

    var path = Routes.projects_list_platform_repository_path($scope.platform_id, $scope.repository_id);
    $http.get(path, { params: params }).then(function(res) {
      $scope.projects = res.data.projects;
      $scope.total_items = res.data.total_items;
      $scope.processing = false;
    }).catch(function() {
      $scope.projects = [];
      $scope.processing = false;
    });

    return true;
  };

  $scope.search = function() {
    var params = {
      owner_name: $('#project_owner').val(),
      project_name: $('#project_name').val()
    };
    $location.search(params);
  };

  $scope.$on('$locationChangeSuccess', function(event) {
    $scope.updateParams();
    $scope.refresh();
  });

  $scope.updateParams = function() {
    var params = $location.search();
    $('#project_owner').val(params['owner_name']);
    $('#project_name').val(params['project_name']);
    $('#page').val(params['page']);
  };

  $scope.goToPage = function(number) {
    $location.search('page', number);
  };

  $scope.removeProject = function(project) {
    if (!confirmMessage.show()) {
      return false;
    }

    $http.delete(project.remove_path).success(function(res) {
      $.notify(res.data.message, 'success');
    });

    $scope.projects = _.reject($scope.projects, function(pr) {
      return pr.id === project.id;
    });

    return false;
  };

}]);

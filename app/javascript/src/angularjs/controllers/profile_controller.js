RosaABF.controller('ProfileController', ['$scope', '$http', '$location', function($scope, $http, $location) {

  $scope.subject = $('#subject_uname').val();
  $scope.processing = true;
  $scope.projects = [];
  $scope.page = null;
  $scope.total_items = null;

  $scope.term = null;
  $scope.visibility = 'all';

  // Fixes: redirect to page after form submit
  $("#search_projects_form").on('submit', function() {
    return false;
  });

  $scope.refresh = function() {
    $scope.processing = true;

    var params = {
      term: $scope.term,
      visibility: $scope.visibility,
      page: $scope.page,
      format: 'json'
    };

    $http.get(Routes.user_path($scope.subject), { params: params })
      .then(function(res) {
        $scope.projects = res.data.projects;
        $scope.total_items = res.data.total_items;
        $scope.processing = false;
      })
      .catch(function() {
        $scope.projects = [];
        $scope.processing = false;
      });

    return true;
  };

  $scope.search = function() {
    var params = {
      term: $scope.term,
      visibility: $scope.visibility
    };
    $location.search(params);
  };

  $scope.$on('$locationChangeSuccess', function(event) {
    $scope.updateParams();
    $scope.refresh();
  });

  $scope.updateParams = function() {
    var params = $location.search();
    $scope.term = params['term'];
    if (params['visibility']) {
      $scope.visibility = params['visibility'];
    }
    $scope.page = params['page'];
  };

  $scope.goToPage = function(number) {
    $location.search('page', number);
  };

}]);

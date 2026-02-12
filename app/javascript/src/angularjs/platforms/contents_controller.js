RosaABF.controller('ContentsController', ['$scope', '$http', '$location', function($scope, $http, $location) {

  $scope.platform = $('#platform_name').val();
  $scope.processing = true;
  $scope.contents = [];
  $scope.folders = [];
  $scope.page = null;
  $scope.total_items = null;

  // Fixes: redirect to page after form submit
  $("#search_contents_form").on('submit', function() {
    return false;
  });

  $scope.refresh = function() {
    $scope.processing = true;

    var params = {
      platform_id: $scope.platform,
      path: $('#path').val(),
      term: $('#platform_term').val(),
      page: $('#page').val(),
      format: 'json'
    };

    $http.get(Routes.platform_contents_path(params)).then(function(res) {
      $scope.folders = res.data.folders;
      $scope.contents = res.data.contents;
      $scope.total_items = res.data.total_items;
      $scope.back = res.data.back;
      $scope.processing = false;
    }).catch(function() {
      $scope.contents = [];
      $scope.processing = false;
    });

    return true;
  };

  $scope.open = function($event, content) {
    if ($scope.processing && $event) {
      return $event.preventDefault();
    }

    if ($.type(content) === 'string') {
      $location.search('path', content);
    } else if (content.is_folder) {
      $location.search('path', content.subpath);
    }

    if ($event) {
      $event.preventDefault();
    }
  };

  $scope.destroy = function(content) {
    var params = {
      path: content.subpath,
      format: 'json'
    };

    content.processing = true;
    $http.delete(Routes.remove_file_platform_contents_path($scope.platform, params)).then(function() {
      $scope.refresh();
    }).catch(function() {
      $scope.refresh();
    });

    return true;
  };

  $scope.search = function() {
    $location.search('term', $('#platform_term').val());
  };

  $scope.$on('$locationChangeSuccess', function(event) {
    $scope.updateParams();
    $scope.refresh();
  });

  $scope.updateParams = function() {
    var params = $location.search();
    $('#path').val(params['path']);
    $('#platform_term').val(params['term']);
    $('#page').val(params['page']);
  };

  $scope.goToPage = function(number) {
    $location.search('page', number);
  };

}]);

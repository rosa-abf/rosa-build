RosaABF.controller('BuildListsController', ['$scope', '$http', '$location', '$timeout', function($scope, $http, $location, $timeout) {

  $scope.filter         = null;
  $scope.first_run      = true;
  $scope.server_status  = null;
  $scope.build_lists    = [];
  $scope.isRequest      = false; // Disable 'Search' button
  $scope.will_paginate  = '';

  // Fixes: redirect to page after form submit
  $("#monitoring_filter").on('submit', function(){ return false; });



  $scope.getBuildLists = function() {
    $scope.isRequest = true;
    $http.get('/build_lists.json', {params: $location.search()}).success(function(results) {
      $scope.server_status  = results.server_status;
      $scope.build_lists = [];
      var groups = {};
      _.each(results.build_lists, function(r){
        var bl = new BuildList(r);
        var key = bl.project_id + '-' + bl.commit_hash;
        if (groups[key]) {
          groups[key].addRelated(bl);
        } else {
          groups[key] = bl;
        }
        $scope.build_lists.push(bl);
      });
      $scope.will_paginate = results.will_paginate;
      $scope.isRequest = false;
    }).error(function(data, status, headers, config) {
      console.log(config);
      $scope.isRequest = false;
    });;
  }


  $scope.showGroup = function(bl) {
    if (bl.relatedHidden) {
      bl.relatedHidden = false;
      _.each(bl.related, function(b){
        b.show = true;
        $timeout(function() {
          $('#build-list-' + b.id + ' td:visible').effect('highlight', {}, 1000);
        }, 100);
      });
    } else {
      bl.relatedHidden = true;
      _.each(bl.related, function(b){ b.show = false; });
      bl.show = true;
    }
  }

  $scope.defaultValues = {
    'filter[ownership]':  'owned',
    'per_page':           25,
    'page':               1
  }
  $scope.cancelRefresh = null;
  $scope.refresh = function(force) {
    if ($('#autoreload').is(':checked') || force) {
      if ($.isEmptyObject($location.search()) || !$scope.first_run) {
        var array = $("#monitoring_filter").serializeArray();
        var params = {};
        for(i=0; i<array.length; i++){
          var a = array[i];
          if (a.value) {
            params[a.name] = a.value.match(/^\{/) ? $scope.defaultValues[a.name] : a.value;
          }
        }
        if (force) { params.page = 1; }
        $location.search(params);
      }
      $scope.first_run = false;
      $scope.getBuildLists();
    }
    if (!force) {
      $scope.cancelRefresh = $timeout($scope.refresh, 60000);
    }
  }
  $scope.refresh();


  $scope.$on('$locationChangeSuccess', function(event) {
    $scope.updateFilter();
  });

  $scope.updateFilter = function() {
    var params = $location.search();
    var current_page = $scope.filter ? $scope.filter.page : null;
    $scope.filter    = {
      page:               params['page'] || $scope.defaultValues['page'],
      per_page:           params['per_page'] || $scope.defaultValues['per_page'],
      ownership:          params['filter[ownership]'] || $scope.defaultValues['filter[ownership]'],
      status:             params['filter[status]'],
      platform_id:        params['filter[platform_id]'],
      arch_id:            params['filter[arch_id]'],
      mass_build_id:      params['filter[mass_build_id]'],
      updated_at_start:   params['filter[updated_at_start]'],
      updated_at_end:     params['filter[updated_at_end]'],
      project_name:       params['filter[project_name]'],
      id:                 params['filter[id]']
    }
    if (current_page && current_page != $scope.filter.page) { $scope.getBuildLists(); }
  }

}]);
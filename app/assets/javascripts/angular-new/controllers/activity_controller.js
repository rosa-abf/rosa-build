RosaABF.controller('ActivityCtrl', ['$scope', '$http', '$timeout', '$q', '$filter',
  function($scope, $http, $timeout, $q, $filter) {
    $scope.activity_tab      = { title: 'activity_menu.activity_feed', active: false, filter: 'all',
                                 all: {}, code: {}, tracker: {}, build: {}, wiki: {} };
    $scope.tracker_tab       = { title: 'activity_menu.tracker',       content: [] , active: false,
                                 filter: { all: true, assigned: false, created: false, name: 'all',
                                           all_count: 0, assigned_count: 0, created_count: 0, closed_count: 0 },
                                 sort: { sort: 'updated', direction: 'desc', updated_class: 'fa-chevron-up' },
                                 status: 'open', pagination: { page: 1, total_count: 0 } };
    $scope.pull_requests_tab = { title: 'activity_menu.pull_requests', content: [] , active: false,
                                 filter: { all: true, assigned: false, created: false, name: 'all',
                                           all_count: 0, assigned_count: 0, created_count: 0, closed_count: 0 },
                                 sort: { sort: 'updated', direction: 'desc', updated_class: 'fa-chevron-up' },
                                 status: 'open', pagination: { page: 1, total_count: 0 } };

    $scope.init = function(active_tab) {
      if(active_tab === 'activity') {
        $scope.activity_tab.active = true;
      }
      else if(active_tab === 'issues') {
        $scope.tracker_tab.active = true;
      }
      else if(active_tab === 'pull_requests') {
        $scope.pull_requests_tab.active = true;
      };
    };

    $scope.getContent = function(tab){
      var cur_tab = $scope.$eval(tab+'_tab');
      if (tab === 'activity') {
        $scope.getActivityContent();
      }
      else if (tab === 'tracker') {
        $scope.tracker_tab.active = true;
        $scope.pull_requests_tab.active = false;
        $scope.getIssuesContent();
      }
      else if (tab === 'pull_requests') {
        $scope.tracker_tab.active = false;
        $scope.pull_requests_tab.active = true;
        $scope.getIssuesContent();
      };
    };

    getIssuesTab = function(kind) {
      if(kind === 'tracker') {
        return $scope.tracker_tab;
      }
      else if(kind === 'pull_requests') {
        return $scope.pull_requests_tab;
      };
    };

    $scope.getTimeLinefaClass = function(content) {
        var template = 'btn-warning fa-question';

        switch(content.kind) {
            case 'build_list_notification':
              template = 'btn-success fa-gear';
              break;
            case 'new_comment_notification':
            case 'new_comment_commit_notification':
              template = 'btn-warning fa-comment';
              break;
            case 'git_new_push_notification':
              template = 'bg-primary fa-sign-in';
              break;
            case 'new_issue_notification':
              template = 'btn-warning fa-check-square-o';
              break;
        };

        return template;
    }

    $scope.getCurActivity = function() {
      return $scope.activity_tab[$scope.activity_tab.filter];
    };

    $scope.needShowTimeLabel = function(index) {
      var feed = $scope.getCurActivity().feed;
      if (feed === undefined) {
        return false;
      };
      var cur_date  = $filter('amDateFormat')(feed[index].date, 'll');
      var prev_date = index == 0 || $filter('amDateFormat')(feed[index-1].date, 'll');
      return cur_date !== prev_date;
    };

    $scope.getTemplate = function(content) {
      return content.kind + '.html';
    };

    $scope.load_more = function() {
      var cur_tab = $scope.getCurActivity();
      var path = cur_tab.next_page_link;
      if(!path) {
        return;
      };
      $http.get(path).then(function(res){
        cur_tab.feed.push.apply(cur_tab.feed, res.data.feed);
        cur_tab.next_page_link = res.data.next_page_link;
      });
    };

    $scope.changeActivityFilter = function(filter) {
      $scope.activity_tab.filter = filter;
      $scope.getActivityContent();
    };

    $scope.getActivityContent = function() {
      var path = Routes.root_path({ filter: $scope.activity_tab.filter, format: 'json' });
      $http.get(path).then(function(res) {
        $scope.getCurActivity().feed = res.data.feed;
        $scope.getCurActivity().next_page_link = res.data.next_page_link;
      });
    };

    $scope.setIssuesFilter = function(kind, issues_filter) {
      var filter = getIssuesTab(kind).filter;

      filter.all            = false;
      filter.assigned       = false;
      filter.created        = false;
      filter[issues_filter] = true;
      filter.name           = issues_filter;
      $scope.getIssuesContent();
    };

    $scope.getIssuesContent = function() {
      if($scope.tracker_tab.active) {
        var tab = $scope.tracker_tab;
        var path = Routes.issues_path({ filter: tab.filter.name,
                     sort: tab.sort.sort,
                     direction: tab.sort.direction,
                     status: tab.status,
                     page: tab.pagination.page,
                     format: 'json' });
      }
      else if($scope.pull_requests_tab.active) {
        var tab = $scope.pull_requests_tab;
        var path = Routes.pull_requests_path({ filter: tab.filter.name,
                     sort: tab.sort.sort,
                     direction: tab.sort.direction,
                     status: tab.status,
                     page: tab.pagination.page,
                     format: 'json' });
      };

      $http.get(path).then(function(res) {
        tab.content                = res.data.content;
        tab.filter.all_count       = res.data.all_count;
        tab.filter.assigned_count  = res.data.assigned_count;
        tab.filter.created_count   = res.data.created_count;
        tab.filter.closed_count    = res.data.closed_count;
        tab.filter.open_count      = res.data.open_count;
        tab.pagination.page        = res.data.page;
        tab.pagination.total_items = parseInt(res.data.issues_count, 10);
      });
    };

    $scope.setIssuesSort = function(kind, issues_sort) {
      var tab = getIssuesTab(kind);
      if(tab.sort.direction === 'desc') {
        tab.sort = { sort: issues_sort, direction: 'asc' };
        var sort_class = 'fa-chevron-down';
      }
      else {
        tab.sort = { sort: issues_sort, direction: 'desc' };
        var sort_class = 'fa-chevron-up';
      };
      tab.sort[issues_sort+'_class'] = sort_class;
      $scope.getIssuesContent();
    };

    $scope.setIssuesStatus = function(kind, issues_status) {
      var tab = getIssuesTab(kind);
      tab.status = issues_status;
      $scope.getIssuesContent();
    };

    $scope.selectPage = function(kind, page) {
      getIssuesTab(kind).pagination.page = page;
      $scope.getIssuesContent();
    };
}]);

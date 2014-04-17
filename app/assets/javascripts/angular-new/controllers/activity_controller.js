RosaABF.controller('ActivityCtrl', ['$scope', '$http', '$timeout', '$q', '$filter',
  function($scope, $http, $timeout, $q, $filter) {
    $scope.activity_tab      = { title: 'activity_menu.activity_feed', active: true, filter: 'all',
                                 all: {}, code: {}, tracker: {}, build: {}, wiki: {} };
    $scope.tracker_tab       = { title: 'activity_menu.tracker',       content: [] , active: false };
    $scope.pull_requests_tab = { title: 'activity_menu.pull_requests', content: [] , active: false };

     $scope.getContent=function(tab){
      var cur_tab = $scope.$eval(tab+'_tab');
      /* make request for data */
      var path = Routes.root_path({ filter: cur_tab.filter, format: 'json' });
      $http.get(path).then(function(res){
        cur_tab[cur_tab.filter].feed = res.data.feed;
        cur_tab[cur_tab.filter].next_page_link = res.data.next_page_link;
      });
    }

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
        }

        return template;
    }

    $scope.getCurActivity = function() {
      return $scope.activity_tab[$scope.activity_tab.filter];
    };

    $scope.needShowTimeLabel = function(index) {
      var cur_date  = $filter('amDateFormat')($scope.getCurActivity().feed[index].date, 'll');
      var prev_date = index == 0 || $filter('amDateFormat')($scope.getCurActivity().feed[index-1].date, 'll');
      return cur_date !== prev_date;
    };

    $scope.isComment = function(content) {
      return content.kind === 'new_comment_notification' ||
             content.kind === 'new_comment_commit_notification';
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
}]);

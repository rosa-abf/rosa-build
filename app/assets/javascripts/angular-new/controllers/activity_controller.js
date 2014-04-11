RosaABF.controller('ActivityCtrl', ['$scope', '$http', '$timeout', '$q', '$filter',
  function($scope, $http, $timeout, $q, $filter) {
    $scope.activity_tab      = { title: 'activity_menu.activity_feed', content: [] , isLoaded: false , active: true  };
    $scope.tracker_tab       = { title: 'activity_menu.tracker',       content: [] , isLoaded: false , active: false };
    $scope.pull_requests_tab = { title: 'activity_menu.pull_requests', content: [] , isLoaded: false , active: false };

    var today = moment().startOf('day');
    // $scope.activity_tab.content = [{date: today, kind:'new_comment_notification'},
    //                                {date: today, kind:'git_new_push_notification'},
    //                                {date: moment().add('days', 1), kind:'build_list_notification'}];

     $scope.getContent=function(tab){
      var cur_tab = $scope.$eval(tab+'_tab');
      /* see if we have data already */
      if(cur_tab.isLoaded){
        return;
      }
      /* or make request for data */
      var path = Routes.root_path({ filter: cur_tab.filter, format: 'json' });
      $http.get(path).then(function(res){
        cur_tab.content=res.data;
        cur_tab.isLoaded=true;
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

    $scope.needShowTimeLabel = function(index) {
      var cur_date  = $filter('amDateFormat')($scope.activity_tab.content[index].date, 'll');
      var prev_date = index == 0 || $filter('amDateFormat')($scope.activity_tab.content[index-1].date, 'll');
      return cur_date !== prev_date;
    };

    $scope.isComment = function(content) {
      return content.kind === 'new_comment_notification' ||
             content.kind === 'new_comment_commit_notification';
    };

    $scope.getTemplate = function(content) {
      if(content.kind == 'new_commit_notification' || content.kind == 'git_new_push_notification' ||
         content.kind == 'git_delete_branch_notification' || content.kind == 'new_issue_notification') {
        return content.kind + '.html';}
      else return 'new_comment_notification.html';
    };

}]);

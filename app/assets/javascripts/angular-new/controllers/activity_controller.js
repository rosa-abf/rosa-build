RosaABF.controller('ActivityCtrl', ['$scope', '$http', '$timeout', '$q',
  function($scope, $http, $timeout, $q) {
    $scope.activity_tab      = { title: 'activity_menu.activity_feed', content: [] , isLoaded: false , active: true  };
    $scope.tracker_tab       = { title: 'activity_menu.tracker',       content: [] , isLoaded: false , active: false };
    $scope.pull_requests_tab = { title: 'activity_menu.pull_requests', content: [] , isLoaded: false , active: false };

    var today = moment().startOf('day');
    $scope.activity_tab.content = [{date: today, test:'adf'}, {date: today.add('days', 1).calendar, test:'fd'}];

    $scope.getContent=function(tab){
      var cur_tab = $scope.$eval(tab+'_tab');
      /* see if we have data already */
      if(cur_tab.isLoaded){
        return;
      }
      /* or make request for data */
      var path = Routes.root_path({ filter: cur_tab.filter, format: 'json' });
      $http.get(path, { tracker: 'activity' }).then(function(res){
        //cur_tab.content=res.data;
        cur_tab.isLoaded=true;
      });
    }

    $scope.getTimeLinefaClass = function(contentType) {
        var template = 'bg-warning fa-question';

        switch(contentType) {
            case 'build_list_notification':
                template = 'bg-danger fa-gear';
                break;
            case 'new_comment_notification':
                template = 'bg-primary fa-comment';
                break;
            case 'git_new_push_notification':
                template = 'bg-success fa-sign-in';
                break;
        }

        return template;
    }
}]);

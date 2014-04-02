var RosaABF = angular.module('RosaABF', ['ui.bootstrap', 'cgBusy']);

RosaABF.controller('ActivityCtrl', ['$scope', '$http', '$timeout', 'promiseTracker', '$q',
  function($scope, $http, $timeout, promiseTracker, $q) {
  $scope.tabs = [
    { title:"All", content:[] , isLoaded:false , active:true, filter:'all'},
    {  title:"Issues", content:[] , isLoaded:false, filter:'issues' }
  ];

  $scope.getContent=function(tabIndex){

    /* see if we have data already */
    if($scope.tabs[tabIndex].isLoaded){
      return
    }
    /* or make request for data */
    var path = Routes.root_path({ filter: $scope.tabs[tabIndex].filter, format: 'json' });
    $http.get(path, { tracker: 'activity' }).then(function(res){
      $scope.tabs[tabIndex].content=res.data;
      $scope.tabs[tabIndex].isLoaded=true;
    });
  }
}]);

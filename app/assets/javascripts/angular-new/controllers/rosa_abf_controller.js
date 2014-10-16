RosaABF.controller('RosaABFController', ['$scope', 'LocalesHelper', 'SoundNotificationsHelper',
                   function($scope, LocalesHelper, SoundNotificationsHelper) {
  $scope.init = function(locale, sound_notifications) {
  	LocalesHelper.setLocale(locale);
    moment.locale(locale);
    SoundNotificationsHelper.enabled(sound_notifications);
  }
}]);

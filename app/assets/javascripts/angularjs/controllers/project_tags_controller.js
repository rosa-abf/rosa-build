RosaABF.controller('ProjectTagsController', ['$scope', '$http', 'ApiProject', function($scope, $http, ApiProject) {

  $scope.tags             = [];
  $scope.project_resource = null;

  $scope.init = function(owner_uname, project_name) {
    $scope.project_resource = ApiProject.resource.get(
      {owner: owner_uname, project: project_name},
      function(results) {
        $scope.project = new Project(results.project);
        $scope.getTags();
      }
    );

  }

  $scope.getTagSha1 = function(tag, type, e) {
    e.preventDefault();
    $http({
      method: 'GET',
      url: tag.get_sha1_of_archive_path($scope.project, type)
    }).then(function(response) {
      tag.sha_types[type] = response.data;
    })
  }

  $scope.getTags = function() {

    $scope.project_resource.$tags(
      {owner: $scope.project.owner.uname, project: $scope.project.name},
      function(results) {
        $scope.tags = [];
        _.each(results.refs_list, function(ref){
          $scope.tags.push(new ProjectRef(ref));
        });
      }
    );

  }

}]);
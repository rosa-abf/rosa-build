var massBuildService = function($http) {
  return {
    get_projects: function(platform_id, repo_id) {
      var path = Routes.projects_list_platform_repository_path(platform_id, repo_id, { text: true });

      return $http.get(path, {
        transformResponse: function(data, headers) {
          return data;
        }
      });
    }
  };
};

angular
  .module("RosaABF")
  .factory("MassBuild", massBuildService);

massBuildService.$inject = ['$http'];

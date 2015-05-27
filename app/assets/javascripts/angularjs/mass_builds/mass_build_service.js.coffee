massBuildService = ($http) ->
  {
    get_projects: (platform_id, repo_id) ->
      path = Routes.projects_list_platform_repository_path(
        platform_id,
        repo_id,
        {
          text: true
        }
      )

      $http.get(path, {
        transformResponse: (data, headers)->
          data
      })
  }

angular
  .module("RosaABF")
  .factory "MassBuild", massBuildService

massBuildService.$inject = ['$http']

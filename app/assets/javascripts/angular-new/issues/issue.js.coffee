issueService = ($http) ->
  {
    getIssues: (project, filter) ->
      params =  {
                  kind:      filter.kind
                  filter:    filter.name
                  sort:      filter.sort
                  direction: filter.sort_direction
                  status:    filter.status
                  labels:    filter.labels
                  page:      filter.page
                }

      path = Routes.project_issues_path(project, params)
      $http.get(path)

  }

angular
  .module("RosaABF")
  .factory "Issue", issueService

issueService.$inject = ['$http']

issueService = ($http) ->
  getFormParams = (kind) ->
    if kind is 'title_body'
      {
        issue: {
          title: $('#issue_title').val()
          body:  $('#issue_body').val()
        }
      }
    else if kind is 'labels'
      {
        update_labels: true
        issue: {
          labelings_attributes: {

          }
        }
      }
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

    getAssignees: (project, val) ->
      path = Routes.search_collaborators_project_issues_path(project, {search_user: val})
      $http.get(path)

    update: (project, id, kind, extra = {}) ->
      params = getFormParams(kind, extra)
      path = Routes.project_issue_path(project, id)
      $http.put(path, params)
  }

angular
  .module("RosaABF")
  .factory "Issue", issueService

issueService.$inject = ['$http']

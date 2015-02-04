issueService = ($http) ->
  getFormParams = (kind, extra = {}) ->
    if kind is 'title_body'
      {
        issue: {
          title: $('#issue_title').val()
          body:  $('#issue-body').val()
        }
      }
    else if kind is 'labels'
      if extra.label.selected is false
        is_destroy = '1'
      else
        is_destroy = '0'
      {
        issue: {
          labelings_attributes:
            [{
               id:       extra.label.labeling_id,
               label_id: extra.label.id,
               _destroy: is_destroy
            }]
        }
      }
    else if kind is 'assignee'
      {
        issue: {
          assignee_id: extra.assignee.id
        }
      }
    else if kind is 'status'
      if extra.status.name isnt 'closed'
        status = 'closed'
      else
        status = 'open'

      {
        issue: {
          status: status
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

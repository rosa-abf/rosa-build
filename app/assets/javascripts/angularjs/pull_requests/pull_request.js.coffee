ApiPullRequestService = ($resource, $http) ->

  getPath = (pull, kind) ->
    name_with_owner = pull.owner+'/'+pull.project
    switch kind
      when 'activity' then params = { get_activity: true }
      when 'diff'     then params = { get_diff:     true }
      when 'commits'  then params = { get_commits:  true }
    Routes.project_pull_request_path(name_with_owner, pull.serial_id, params)

  PullRequestResource = $resource("/:owner/:project/pull_requests/:serial_id?format=json",
    owner:     "@pull_request.to_ref.project.owner_uname"
    project:   "@pull_request.to_ref.project.name"
    serial_id: "@pull_request.number"
  ,
    update:
      method: "PUT"
      isArray: false

    merge:
      url: "/:owner/:project/pull_requests/:serial_id/merge"
      format: "json"
      method: "PUT"
      isArray: false
  )

  get_activity = (params) ->
    path = getPath(params, 'activity')
    $http.get(path)

  get_diff = (params) ->
    path = getPath(params, 'diff')
    $http.get(path)

  get_commits = (params) ->
    path = getPath(params, 'commits')
    $http.get(path)

  resource: PullRequestResource
  get_activity: get_activity
  get_diff:     get_diff
  get_commits:  get_commits

angular
  .module("RosaABF")
  .factory "ApiPullRequest", ApiPullRequestService

ApiPullRequestService.$inject = ['$resource', '$http']

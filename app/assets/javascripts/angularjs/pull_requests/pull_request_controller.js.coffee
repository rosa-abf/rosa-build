PullRequestController = (dataservice, $http, ApiPullRequest, ApiProject, DateTimeFormatter,
                         compileHTML, $scope, $rootScope) ->
  vm = this

  vm.project_resource    = null

  vm.pull_params         = null
  vm.pull                = null
  vm.pull_resource       = null

  vm.merged_at           = null
  vm.closed_at           = null
  vm.branch              = null

  vm.can_delete_branch   = false

  activity               = $('#pull-activity')
  diff                   = $('#diff.tab-pane .content')
  commits                = $('#commits.tab-pane .content')

  vm.active_tab          = null

  vm.processing          = false
  vm.is_pull_updated     = false
  vm.is_activity_updated = false
  vm.is_diff_updated     = false
  vm.is_commits_updated  = false


  vm.getPullRequest = ->
    vm.pull_resource = ApiPullRequest.resource.get(vm.pull_params, (results) ->
      if vm.pull
        vm.is_pull_updated = vm.pull.updated_at is results.pull_request.updated_at
      else
        vm.is_pull_updated = true
      vm.pull = results.pull_request
      vm.merged_at = DateTimeFormatter.utc(vm.pull.merged_at)  if vm.pull.merged_at
      vm.closed_at = DateTimeFormatter.utc(vm.pull.closed_at)  if vm.pull.closed_at
    )

  # @param [from_ref] - sets only at first time
  vm.getBranch = (from_ref) ->
    vm.project_resource = ApiProject.resource.get(vm.pull_params) unless vm.project_resource

    # Fix: at first load
    # Cannot read property 'from_ref' of null
    from_ref = vm.pull.from_ref.ref unless from_ref
    vm.project_resource.$branches vm.pull_params, (results) ->
      branch = null
      _.each results.refs_list, (b) ->
        if b.ref is from_ref
          branch = new ProjectRef(b)
          true
      vm.branch = branch

  vm.reopen = ->
    vm.pull_resource.$update
      pull_request_action: "reopen"
    , ->
      vm.getPullRequest()

  vm.close = ->
    vm.pull_resource.$update
      pull_request_action: "close"
    , ->
      vm.getPullRequest()

  vm.merge = ->
    vm.pull_resource.$merge ->
      vm.getPullRequest()

  vm.deleteBranch = ->
    vm.project_resource.$delete_branch vm.branch_params(), (-> # success
      vm.branch = null
    ), -> # error
      vm.getBranch()

  vm.restoreBranch = ->
    vm.project_resource.$restore_branch vm.branch_params(), (-> # success
      vm.getBranch()
    ), -> # error
      vm.getBranch()

  vm.branch_params = ->
    owner: vm.pull_params.owner
    project: vm.pull_params.project
    ref: vm.pull.from_ref.ref
    sha: vm.pull.from_ref.sha

  vm.getActivity = ->
    return if vm.is_pull_updated and vm.is_activity_updated
    vm.processing = true

    promise = ApiPullRequest.get_activity(vm.pull_params)
    promise.then (response) ->
      activity.html(null)
      #html = compileHTML.run($scope, response.data)
      #activity.html(html)
      $rootScope.$broadcast('compile_html', { element: activity, html: response.data })
      vm.processing = false
      vm.is_activity_updated = true
    false

  vm.getDiff = ->
    return if vm.is_pull_updated and vm.is_diff_updated
    vm.processing = true

    promise = ApiPullRequest.get_diff(vm.pull_params)
    promise.then (response) ->
      diff.html(null)
      #html = compileHTML.run($scope, response.data)
      #diff.html(html)
      $rootScope.$broadcast('compile_html', { element: diff, html: response.data })
      vm.processing = false
      vm.is_diff_updated = true
    false

  vm.getCommits = ->
    return if vm.is_pull_updated and vm.is_commits_updated
    vm.processing = true

    promise = ApiPullRequest.get_commits(vm.pull_params)
    promise.then (response) ->
      commits.html(null)
      html = compileHTML.run($scope, response.data)
      commits.html(html)
      vm.processing = false
      vm.is_commits_updated = true
    false

  init = (dataservice) ->
    vm.pull_params = dataservice
    vm.getPullRequest()

    if location.href.match(/(.*)#diff(.*)/)
      vm.active_tab = "diff"
      vm.getDiff()
    else if document.location.href.match(/(.*)#commits(.*)/)
      vm.active_tab = "commits"
      vm.getCommits()
    else
      vm.active_tab = 'discussion'
      vm.getActivity()
    $("#pull_tabs a[href=\"#" + vm.active_tab + "\"]").tab "show"
    true

  init(dataservice)
  true

angular
  .module("RosaABF")
  .controller "PullRequestController", PullRequestController

PullRequestController.$inject = [
                                  'PullInitializer'
                                  '$http'
                                  'ApiPullRequest'
                                  'ApiProject'
                                  'DateTimeFormatter'
                                  'compileHTML'
                                  '$scope'
                                  '$rootScope'
                                ]

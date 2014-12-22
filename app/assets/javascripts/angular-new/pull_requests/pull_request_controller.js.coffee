PullRequestController = (dataservice, $http, ApiPullRequest, ApiProject, DateTimeFormatter) ->
  vm = this

  vm.project_resource  = null

  vm.pull_params       = null
  vm.pull              = null
  vm.pull_resource     = null

  vm.merged_at         = null
  vm.closed_at         = null
  vm.branch            = null

  vm.can_delete_branch = false

  vm.getPullRequest = ->
    vm.pull_resource = ApiPullRequest.resource.get(vm.pull_params, (results) ->
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

  init = (dataservice) ->
    vm.pull_params = dataservice

    tab = "discussion"
    if location.href.match(/(.*)#diff(.*)/)
      tab = "diff"
    else tab = "commits"  if document.location.href.match(/(.*)#commits(.*)/)
    $("#pull_tabs a[href=\"#" + tab + "\"]").tab "show"
    vm.getPullRequest()
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
                                ]

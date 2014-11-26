IssuesController = (dataservice, $http, $location, Issue, $rootScope) ->

  getIssues = () ->
    prepareLabelsFilter()
    promise = Issue.getIssues(vm.project, vm.filter)
    promise.then (response) ->
      vm.issues                = response.data.issues

      vm.filter.page           = response.data.page
      vm.filter.all_count      = response.data.all_count
      vm.filter.created_count  = response.data.created_count
      vm.filter.assigned_count = response.data.assigned_count
      vm.filter.opened_count   = response.data.opened_count
      vm.filter.closed_count   = response.data.closed_count
      vm.filter.filtered_count = response.data.filtered_count

      vm.labels                = response.data.labels
    true

  setSortClass = ->
    if vm.filter.sort_direction is 'asc'
      sort_class = 'fa-chevron-down'
    else
      sort_class = 'fa-chevron-up'

    if vm.filter.sort is 'updated'
      vm.updated_class   = sort_class
      vm.submitted_class = null
    else
      vm.updated_class   = null
      vm.submitted_class = sort_class

  prepareLabelsFilter = () ->
    vm.filter.labels = []
    _.each(vm.labels, (l) ->
      vm.filter.labels.push(l.name) if l.selected
    )

  vm = this

  vm.setIssuesFilter = (filter) ->
    vm.filter.all      = false
    vm.filter.assigned = false
    vm.filter.created  = false
    vm.filter[filter]  = true
    vm.filter.name     = filter

    getIssues()

  vm.setIssuesSort = (issues_sort) ->
    if vm.filter.sort_direction is 'desc'
      vm.filter.sort_direction = 'asc'
    else
      vm.filter.sort_direction = 'desc'

    vm.filter.sort = issues_sort
    setSortClass()
    getIssues()

  vm.setIssuesStatus = (issues_status) ->
    vm.filter.status = issues_status
    vm.filter.page   = 1
    getIssues()

  vm.goToPage = (page) ->
    getIssues()

  vm.toggleLabelFilter = (label) ->
    label.selected = !label.selected
    if label.selected
      label.style = label.default_style
    else
      label.style = {}
    getIssues()

  $rootScope.$on "updateIssues", (event, args) ->
    getIssues()

  init = (dataservice) ->
    vm.project = dataservice.project
    vm.issues  = dataservice.issues
    vm.filter  = dataservice.filter

    vm.labels  = dataservice.labels

    vm.filter[dataservice.filter.filter] = true

    if vm.filter.status == "closed"
      vm.filter.status_closed = true
    else
      vm.filter.status_open   = true

    setSortClass()
    getIssues()

  init(dataservice)
  true

angular
  .module("RosaABF")
  .controller "IssuesController", IssuesController

IssuesController.$inject = ['IssuesInitializer', '$http', '$location', 'Issue', '$rootScope']

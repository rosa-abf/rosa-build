IssuesController = (dataservice, $http, $location, Issue) ->

  getIssues = ->
    promise = Issue.getIssues(vm.project, vm.filter)
    promise.then (response) ->
      vm.issues             = response.data.issues
      vm.filter.total_items = response.data.total_items
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

  vm = this

  vm.setIssuesFilter = (filter) ->
    vm.filter.all      = false
    vm.filter.assigned = false
    vm.filter.created  = false
    vm.filter[filter]  = true
    vm.filter.name     = filter

    vm.getIssues()

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

  init = (dataservice) ->
    vm.project     = dataservice.project
    vm.issues      = dataservice.issues
    vm.filter      = dataservice.filter

    if vm.filter.status == "closed"
      vm.filter.status_closed = true
    else
      vm.filter.status_open   = true

    setSortClass()

  init(dataservice)
  true

angular
  .module("RosaABF")
  .controller "IssuesController", IssuesController

IssuesController.$inject = ['IssuesInitializer', '$http', '$location', 'Issue']

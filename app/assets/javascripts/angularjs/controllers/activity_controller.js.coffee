ActivityController = ($scope, $http, $timeout, $q, $filter, $location, ActivityFilter) ->

  getIssuesTab = (kind)->
    return vm.tracker_tab if kind is 'tracker'
    return vm.pull_requests_tab if kind is 'pull_requests'

  calculateChangeDate = (feed)->
    prev_date = null
    _.each(feed, (event)->
      cur_date  = $filter('amDateFormat')(event.date, 'll')
      event.is_date_changed = cur_date isnt prev_date
      prev_date = cur_date
    )

  $scope.$watch (->
    vm.current_activity_tab.owner_uname_filter_tmp
  ), () ->
    vm.selectOwnerFilter({uname: null}, null, null) unless vm.current_activity_tab.owner_uname_filter_tmp

  $scope.$watch (->
    vm.current_activity_tab.project_name_filter_tmp
  ), () ->
    vm.selectProjectNameFilter({name: null}, null, null) unless vm.current_activity_tab.project_name_filter_tmp


  vm = this

  vm.processing   = false
  vm.activity_tab =
    filter: 'all'
    all: {}
    code: {}
    tracker: {}
    build: {}
    wiki: {}
    owner_filter: null
    project_name_filter: null
    owner_uname_filter_tmp: null
    project_name_filter_tmp: null

  vm.own_activity_tab = $.extend({}, vm.activity_tab)
  vm.current_activity_tab = vm.activity_tab

  vm.tracker_tab =
    content: []
    filter:
      all: true
      assigned: false
      created: false
      name: 'all'
    all_count: 0
    assigned_count: 0
    created_count: 0
    closed_count: 0
    sort:
      sort: 'updated'
      direction: 'desc'
      updated_class: 'fa-chevron-up'
    status: 'open'
    pagination:
      page: 1
      total_count: 0

  vm.pull_requests_tab = $.extend({}, vm.tracker_tab)


  vm.init = (active_tab)->
    switch active_tab
      when 'activity'
        vm.activity_tab.active  = true
        vm.current_activity_tab = vm.activity_tab
      when 'own_activity'
        vm.own_activity_tab.active = true
        vm.current_activity_tab    = vm.own_activity_tab
      when 'issues'
        vm.tracker_tab.active = true
      when active_tab is 'pull_requests'
        vm.pull_requests_tab.active = true
    true

  vm.getContent = (tab)->
    switch tab
      when 'activity'
        vm.activity_tab.active      = true
        vm.own_activity_tab.active  = false
        vm.tracker_tab.active       = false
        vm.pull_requests_tab.active = false
        vm.current_activity_tab     = vm.activity_tab
        vm.getActivityContent()
        if $location.path() isnt '/'
          $location.path('/').replace()

      when 'own_activity'
        vm.activity_tab.active      = false
        vm.own_activity_tab.active  = true
        vm.tracker_tab.active       = false
        vm.pull_requests_tab.active = false
        vm.current_activity_tab     = vm.own_activity_tab
        vm.getActivityContent()
        if $location.path() isnt '/own_activity'
          $location.path('/own_activity').replace()

      when 'tracker'
        vm.activity_tab.active      = false
        vm.own_activity_tab.active  = false
        vm.tracker_tab.active       = true
        vm.pull_requests_tab.active = false
        vm.getIssuesContent()
        if $location.path() isnt '/issues'
          $location.path('/issues').replace()

      when 'pull_requests'
        vm.activity_tab.active      = false
        vm.own_activity_tab.active  = false
        vm.tracker_tab.active       = false
        vm.pull_requests_tab.active = true
        vm.getIssuesContent()
        if $location.path() isnt '/pull_requests'
          $location.path('/pull_requests').replace()

  vm.getTimeLinefaClass = (content)->
    template = switch content.kind
      when 'build_list_notification'   then 'btn-success fa-gear'
      when 'new_comment_notification', 'new_comment_commit_notification' then 'btn-warning fa-comment'
      when 'git_new_push_notification' then 'bg-primary fa-sign-in'
      when 'new_issue_notification'    then 'btn-warning fa-check-square-o'
      else 'btn-warning fa-question'
    template

  vm.getCurActivity = ()->
    vm.current_activity_tab[vm.current_activity_tab.filter]

  vm.getTemplate = (content)->
    content.kind + '.html'

  vm.load_more = ()->
    cur_tab = vm.getCurActivity()
    path    = cur_tab.next_page_link
    return unless path

    $http.get(path).then (res)->
      cur_tab.feed.push.apply(cur_tab.feed, res.data.feed)
      cur_tab.next_page_link = res.data.next_page_link

  vm.changeActivityFilter = (filter)->
    return if vm.current_activity_tab.filter is filter
    vm.current_activity_tab.filter = filter
    vm.getActivityContent()

  vm.getActivityContent = ()->
    vm.processing = true
    options =
      filter:              vm.current_activity_tab.filter
      owner_filter:        vm.current_activity_tab.owner_filter
      project_name_filter: vm.current_activity_tab.project_name_filter
      format:              'json'

    if vm.activity_tab.active
      path = Routes.root_path(options)
    else
      path = Routes.own_activity_path(options)

    $http.get(path).then (res)->
      feed = res.data.feed
      vm.getCurActivity().feed = feed
      vm.getCurActivity().next_page_link = res.data.next_page_link
      calculateChangeDate(feed)
      vm.processing = false
      true

  vm.setIssuesFilter = (kind, issues_filter)->
    filter = getIssuesTab(kind).filter

    filter.all            = false
    filter.assigned       = false
    filter.created        = false
    filter[issues_filter] = true
    filter.name           = issues_filter
    vm.getIssuesContent()

  vm.getIssuesContent = ()->
    if vm.tracker_tab.active
      tab = vm.tracker_tab
      path = Routes.issues_path(
                   filter: tab.filter.name
                   sort: tab.sort.sort
                   direction: tab.sort.direction
                   status: tab.status
                   page: tab.pagination.page
                   format: 'json')
    else if vm.pull_requests_tab.active
      tab = vm.pull_requests_tab
      path = Routes.pull_requests_path(
                   filter: tab.filter.name
                   sort: tab.sort.sort
                   direction: tab.sort.direction
                   status: tab.status
                   page: tab.pagination.page
                   format: 'json')

    $http.get(path).then (res)->
      tab.content                = res.data.content
      tab.filter.all_count       = res.data.all_count
      tab.filter.assigned_count  = res.data.assigned_count
      tab.filter.created_count   = res.data.created_count
      tab.filter.closed_count    = res.data.closed_count
      tab.filter.open_count      = res.data.open_count
      tab.pagination.page        = res.data.page
      tab.pagination.total_items = parseInt(res.data.issues_count, 10)

  vm.setIssuesSort = (kind, issues_sort)->
    tab = getIssuesTab(kind)
    if tab.sort.direction is 'desc'
      tab.sort = { sort: issues_sort, direction: 'asc' }
      sort_class = 'fa-chevron-down'
    else
      tab.sort = { sort: issues_sort, direction: 'desc' }
      sort_class = 'fa-chevron-up'

    tab.sort[issues_sort+'_class'] = sort_class
    vm.getIssuesContent()

  vm.setIssuesStatus = (kind, issues_status)->
    tab = getIssuesTab(kind)
    tab.status = issues_status
    tab.pagination.page = 1
    vm.getIssuesContent()

  vm.selectPage = (kind, page)->
    vm.getIssuesContent()

  vm.getOwnersList = (value)->
    return [] if value.length < 1
    ActivityFilter.get_owners(value)

  vm.selectOwnerFilter = (item, model, label)->
    return if vm.current_activity_tab.owner_filter is item.uname

    vm.current_activity_tab.owner_filter            = item.uname
    vm.current_activity_tab.project_name_filter     = null
    vm.current_activity_tab.project_name_filter_tmp = null
    vm.getActivityContent()
    true

  vm.getProjectNamesList = (value)->
    return [] if value.length < 1
    ActivityFilter.get_project_names(vm.current_activity_tab.owner_filter, value)

  vm.selectProjectNameFilter = (item, model, label)->
    return if vm.current_activity_tab.project_name_filter is item.name
    vm.current_activity_tab.project_name_filter = item.name
    vm.getActivityContent()
    true

angular
  .module("RosaABF")
  .controller "ActivityController", ActivityController

ActivityController.$inject = ['$scope', '$http', '$timeout', '$q', '$filter', '$location', 'ActivityFilter']

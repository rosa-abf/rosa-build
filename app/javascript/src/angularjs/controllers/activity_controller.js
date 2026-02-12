var ActivityController = function($scope, $http, $timeout, $q, $filter, $location, ActivityFilter) {

  var getIssuesTab = function(kind) {
    if (kind === 'tracker') {
      return vm.tracker_tab;
    }
    if (kind === 'pull_requests') {
      return vm.pull_requests_tab;
    }
  };

  var calculateChangeDate = function(feed) {
    var prev_date = null;
    _.each(feed, function(event) {
      var cur_date = $filter('amDateFormat')(event.date, 'll');
      event.is_date_changed = cur_date !== prev_date;
      prev_date = cur_date;
    });
  };

  $scope.$watch(function() {
    return vm.current_activity_tab.owner_uname_filter_tmp;
  }, function() {
    if (!vm.current_activity_tab.owner_uname_filter_tmp) {
      vm.selectOwnerFilter({ uname: null }, null, null);
    }
  });

  $scope.$watch(function() {
    return vm.current_activity_tab.project_name_filter_tmp;
  }, function() {
    if (!vm.current_activity_tab.project_name_filter_tmp) {
      vm.selectProjectNameFilter({ name: null }, null, null);
    }
  });

  var vm = this;

  vm.processing = false;
  vm.activity_tab = {
    filter: 'all',
    all: {},
    code: {},
    tracker: {},
    build: {},
    owner_filter: null,
    project_name_filter: null,
    owner_uname_filter_tmp: null,
    project_name_filter_tmp: null
  };

  vm.own_activity_tab = $.extend({}, vm.activity_tab);
  vm.current_activity_tab = vm.activity_tab;

  vm.tracker_tab = {
    content: [],
    filter: {
      all: true,
      assigned: false,
      created: false,
      name: 'all'
    },
    all_count: 0,
    assigned_count: 0,
    created_count: 0,
    closed_count: 0,
    sort: {
      sort: 'updated',
      direction: 'desc',
      updated_class: 'fa-chevron-up'
    },
    status: 'open',
    pagination: {
      page: 1,
      total_count: 0
    }
  };

  vm.pull_requests_tab = $.extend({}, vm.tracker_tab);

  vm.init = function(active_tab) {
    switch (active_tab) {
    case 'activity':
    vm.activity_tab.active = true;
    vm.current_activity_tab = vm.activity_tab;
    break;
    case 'own_activity':
    vm.own_activity_tab.active = true;
    vm.current_activity_tab = vm.own_activity_tab;
    break;
    case 'issues':
    vm.tracker_tab.active = true;
    break;
    default:
    if (active_tab === 'pull_requests') {
      vm.pull_requests_tab.active = true;
    }
    }
    return true;
  };

  vm.getContent = function(tab) {
    switch (tab) {
    case 'activity':
    vm.activity_tab.active = true;
    vm.own_activity_tab.active = false;
    vm.tracker_tab.active = false;
    vm.pull_requests_tab.active = false;
    vm.current_activity_tab = vm.activity_tab;
    vm.getActivityContent();
    if ($location.path() !== '/') {
      $location.path('/').replace();
    }
    break;

    case 'own_activity':
    vm.activity_tab.active = false;
    vm.own_activity_tab.active = true;
    vm.tracker_tab.active = false;
    vm.pull_requests_tab.active = false;
    vm.current_activity_tab = vm.own_activity_tab;
    vm.getActivityContent();
    if ($location.path() !== '/own_activity') {
      $location.path('/own_activity').replace();
    }
    break;

    case 'tracker':
    vm.activity_tab.active = false;
    vm.own_activity_tab.active = false;
    vm.tracker_tab.active = true;
    vm.pull_requests_tab.active = false;
    vm.getIssuesContent();
    if ($location.path() !== '/issues') {
      $location.path('/issues').replace();
    }
    break;

    case 'pull_requests':
    vm.activity_tab.active = false;
    vm.own_activity_tab.active = false;
    vm.tracker_tab.active = false;
    vm.pull_requests_tab.active = true;
    vm.getIssuesContent();
    if ($location.path() !== '/pull_requests') {
      $location.path('/pull_requests').replace();
    }
    break;
    }
  };

  vm.getTimeLinefaClass = function(content) {
    var template;
    switch (content.kind) {
    case 'build_list_notification':
    template = 'btn-success fa-gear';
    break;
    case 'new_comment_notification':
    case 'new_comment_commit_notification':
    template = 'btn-warning fa-comment';
    break;
    case 'git_new_push_notification':
    template = 'bg-primary fa-sign-in';
    break;
    case 'new_issue_notification':
    template = 'btn-warning fa-check-square-o';
    break;
    default:
    template = 'btn-warning fa-question';
    }
    return template;
  };

  vm.getCurActivity = function() {
    return vm.current_activity_tab[vm.current_activity_tab.filter];
  };

  vm.getTemplate = function(content) {
    return content.kind + '.html';
  };

  vm.load_more = function() {
    var cur_tab = vm.getCurActivity();
    var path = cur_tab.next_page_link;
    if (!path) {
      return;
    }

    $http.get(path).then(function(res) {
      cur_tab.feed.push.apply(cur_tab.feed, res.data.feed);
      cur_tab.next_page_link = res.data.next_page_link;
    });
  };

  vm.changeActivityFilter = function(filter) {
    if (vm.current_activity_tab.filter === filter) {
      return;
    }
    vm.current_activity_tab.filter = filter;
    vm.getActivityContent();
  };

  vm.getActivityContent = function() {
    vm.processing = true;
    var options = {
      filter: vm.current_activity_tab.filter,
      owner_filter: vm.current_activity_tab.owner_filter,
      project_name_filter: vm.current_activity_tab.project_name_filter,
      format: 'json'
    };

    var path;
    if (vm.activity_tab.active) {
      path = Routes.root_path(options);
    } else {
      path = Routes.own_activity_path(options);
    }

    $http.get(path).then(function(res) {
      var feed = res.data.feed;
      vm.getCurActivity().feed = feed;
      vm.getCurActivity().next_page_link = res.data.next_page_link;
      calculateChangeDate(feed);
      vm.processing = false;
      return true;
    });
  };

  vm.setIssuesFilter = function(kind, issues_filter) {
    var filter = getIssuesTab(kind).filter;

    filter.all = false;
    filter.assigned = false;
    filter.created = false;
    filter[issues_filter] = true;
    filter.name = issues_filter;
    vm.getIssuesContent();
  };

  vm.getIssuesContent = function() {
    var tab;
    var path;

    if (vm.tracker_tab.active) {
      tab = vm.tracker_tab;
      path = Routes.issues_path({
                                filter: tab.filter.name,
                                sort: tab.sort.sort,
                                direction: tab.sort.direction,
                                status: tab.status,
                                page: tab.pagination.page,
                                format: 'json'
      });
    } else if (vm.pull_requests_tab.active) {
      tab = vm.pull_requests_tab;
      path = Routes.pull_requests_path({
                                       filter: tab.filter.name,
                                       sort: tab.sort.sort,
                                       direction: tab.sort.direction,
                                       status: tab.status,
                                       page: tab.pagination.page,
                                       format: 'json'
      });
    }

    $http.get(path).then(function(res) {
      tab.content = res.data.content;
      tab.filter.all_count = res.data.all_count;
      tab.filter.assigned_count = res.data.assigned_count;
      tab.filter.created_count = res.data.created_count;
      tab.filter.closed_count = res.data.closed_count;
      tab.filter.open_count = res.data.open_count;
      tab.pagination.page = res.data.page;
      tab.pagination.total_items = parseInt(res.data.issues_count, 10);
    });
  };

  vm.setIssuesSort = function(kind, issues_sort) {
    var tab = getIssuesTab(kind);
    var sort_class;

    if (tab.sort.direction === 'desc') {
      tab.sort = { sort: issues_sort, direction: 'asc' };
      sort_class = 'fa-chevron-down';
    } else {
      tab.sort = { sort: issues_sort, direction: 'desc' };
      sort_class = 'fa-chevron-up';
    }

    tab.sort[issues_sort + '_class'] = sort_class;
    vm.getIssuesContent();
  };

  vm.setIssuesStatus = function(kind, issues_status) {
    var tab = getIssuesTab(kind);
    tab.status = issues_status;
    tab.pagination.page = 1;
    vm.getIssuesContent();
  };

  vm.selectPage = function(kind, page) {
    vm.getIssuesContent();
  };

  vm.getOwnersList = function(value) {
    if (value.length < 1) {
      return [];
    }
    return ActivityFilter.get_owners(value);
  };

  vm.selectOwnerFilter = function(item, model, label) {
    if (vm.current_activity_tab.owner_filter === item.uname) {
      return;
    }

    vm.current_activity_tab.owner_filter = item.uname;
    vm.current_activity_tab.project_name_filter = null;
    vm.current_activity_tab.project_name_filter_tmp = null;
    vm.getActivityContent();
    return true;
  };

  vm.getProjectNamesList = function(value) {
    if (value.length < 1) {
      return [];
    }
    return ActivityFilter.get_project_names(vm.current_activity_tab.owner_filter, value);
  };

  vm.selectProjectNameFilter = function(item, model, label) {
    if (vm.current_activity_tab.project_name_filter === item.name) {
      return;
    }
    vm.current_activity_tab.project_name_filter = item.name;
    vm.getActivityContent();
    return true;
  };
};

angular
  .module("RosaABF")
  .controller("ActivityController", ActivityController);

ActivityController.$inject = ['$scope', '$http', '$timeout', '$q', '$filter', '$location', 'ActivityFilter'];

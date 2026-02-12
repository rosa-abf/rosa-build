var PullRequestController = function(dataservice, $http, ApiPullRequest, ApiProject, DateTimeFormatter,
                                     compileHTML, $scope, $rootScope) {
  var vm = this;

  vm.project_resource = null;

  vm.pull_params = null;
  vm.pull = null;
  vm.pull_resource = null;

  vm.merged_at = null;
  vm.closed_at = null;
  vm.branch = null;

  vm.can_delete_branch = false;

  var activity = $('#pull-activity');
  var diff = $('#diff.tab-pane .content');
  var commits = $('#commits.tab-pane .content');

  vm.active_tab = null;

  vm.processing = false;
  vm.is_pull_updated = false;
  vm.is_activity_updated = false;
  vm.is_diff_updated = false;
  vm.is_commits_updated = false;

  vm.getPullRequest = function() {
    vm.pull_resource = ApiPullRequest.resource.get(vm.pull_params, function(results) {
      if (vm.pull) {
        vm.is_pull_updated = vm.pull.updated_at === results.pull_request.updated_at;
      } else {
        vm.is_pull_updated = true;
      }
      vm.pull = results.pull_request;
      if (vm.pull.merged_at) {
        vm.merged_at = DateTimeFormatter.utc(vm.pull.merged_at);
      }
      if (vm.pull.closed_at) {
        vm.closed_at = DateTimeFormatter.utc(vm.pull.closed_at);
      }
    });
  };

  // @param [from_ref] - sets only at first time
  vm.getBranch = function(from_ref) {
    if (!vm.project_resource) {
      vm.project_resource = ApiProject.resource.get(vm.pull_params);
    }

    // Fix: at first load
    // Cannot read property 'from_ref' of null
    if (!from_ref) {
      from_ref = vm.pull.from_ref.ref;
    }

    vm.project_resource.$branches(vm.pull_params, function(results) {
      var branch = null;
      _.each(results.refs_list, function(b) {
        if (b.ref === from_ref) {
          branch = new ProjectRef(b);
          return true;
        }
      });
      vm.branch = branch;
    });
  };

  vm.reopen = function() {
    if (vm.processing) {
      return false;
    }
    vm.processing = true;
    vm.pull_resource.$update({
                             pull_request_action: "reopen"
    }, function() {
      vm.getPullRequest();
      vm.processing = false;
    });
  };

  vm.close = function() {
    if (vm.processing) {
      return false;
    }
    vm.processing = true;
    vm.pull_resource.$update({
                             pull_request_action: "close"
    }, function() {
      vm.getPullRequest();
      vm.processing = false;
    });
  };

  vm.merge = function() {
    if (vm.processing) {
      return false;
    }
    vm.processing = true;
    vm.pull_resource.$merge(function() {
      vm.getPullRequest();
      vm.processing = false;
    });
  };

  vm.deleteBranch = function() {
    if (vm.processing) {
      return false;
    }
    vm.processing = true;
    vm.project_resource.$delete_branch(vm.branch_params(), function() { // success
      vm.branch = null;
      vm.processing = false;
    }, function() { // error
      vm.getBranch();
      vm.processing = false;
    });
  };

  vm.restoreBranch = function() {
    if (vm.processing) {
      return false;
    }
    vm.processing = true;
    vm.project_resource.$restore_branch(vm.branch_params(), function() { // success
      vm.getBranch();
      vm.processing = false;
    }, function() { // error
      vm.getBranch();
      vm.processing = false;
    });
  };

  vm.branch_params = function() {
    return {
      owner: vm.pull_params.owner,
      project: vm.pull_params.project,
      ref: vm.pull.from_ref.ref,
      sha: vm.pull.from_ref.sha
    };
  };

  vm.getActivity = function() {
    if (vm.is_pull_updated && vm.is_activity_updated) {
      return;
    }
    vm.processing = true;

    var promise = ApiPullRequest.get_activity(vm.pull_params);
    promise.then(function(response) {
      activity.html(null);
      //html = compileHTML.run($scope, response.data)
      //activity.html(html)
      $rootScope.$broadcast('compile_html', { element: activity, html: response.data });
      vm.processing = false;
      vm.is_activity_updated = true;
    });
    return false;
  };

  vm.getDiff = function() {
    if (vm.is_pull_updated && vm.is_diff_updated) {
      return;
    }
    vm.processing = true;

    var promise = ApiPullRequest.get_diff(vm.pull_params);
    promise.then(function(response) {
      diff.html(null);
      $rootScope.$broadcast('compile_html', { element: diff, html: response.data });
      $('[data-toggle="tooltip"]').tooltip();
      vm.processing = false;
      vm.is_diff_updated = true;
    });
    return false;
  };

  vm.getCommits = function() {
    if (vm.is_pull_updated && vm.is_commits_updated) {
      return;
    }
    vm.processing = true;

    var promise = ApiPullRequest.get_commits(vm.pull_params);
    promise.then(function(response) {
      commits.html(null);
      var html = compileHTML.run($scope, response.data);
      commits.html(html);
      vm.processing = false;
      vm.is_commits_updated = true;
    });
    return false;
  };

  var init = function(dataservice) {
    vm.pull_params = dataservice;
    vm.getPullRequest();

    if (location.href.match(/(.*)#diff(.*)/)) {
      vm.active_tab = "diff";
      vm.getDiff();
    } else if (document.location.href.match(/(.*)#commits(.*)/)) {
      vm.active_tab = "commits";
      vm.getCommits();
    } else {
      vm.active_tab = 'discussion';
      vm.getActivity();
    }
    $("#pull_tabs a[href=\"#" + vm.active_tab + "\"]").tab("show");
    return true;
  };

  init(dataservice);
  return true;
};

angular
  .module("RosaABF")
  .controller("PullRequestController", PullRequestController);

PullRequestController.$inject = [
  'PullInitializer',
  '$http',
  'ApiPullRequest',
  'ApiProject',
  'DateTimeFormatter',
  'compileHTML',
  '$scope',
  '$rootScope'
];

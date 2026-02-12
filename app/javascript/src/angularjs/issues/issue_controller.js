var IssueController = function(dataservice, $http, Issue, $rootScope, Preview, Label, confirmMessage) {

  var updateIssueFromResponse = function(response) {
    $('#issue_title_text').html(response.data.title);
    $('#issue_body_text').html(response.data.body);
    vm.assignee = response.data.assignee;
    vm.labels = response.data.labels;
    vm.status = response.data.status;

    updateStatusCLass();
  };

  var getLabels = function() {
    var promise = Label.get_labels(vm.project);
    promise.then(function(response) {
      var old_labels = vm.labels;
      vm.labels = response.data;
      _.each(vm.labels, function(l) {
        _.each(old_labels, function(ol) {
          if (l.id === ol.id) {
            l.selected = ol.selected;
            l.style = ol.style;
            l.selected_id = ol.selected_id;
          }
        });
      });
    });
    return true;
  };

  var updateStatusCLass = function() {
    if (vm.status.name === 'open' || vm.status.name === 'reopen') {
      vm.issue_status_class = 'btn-primary';
    } else {
      vm.issue_status_class = 'btn-danger';
    }
  };

  var vm = this;

  vm.previewBody = function() {
    var body = $('#issue-body').val();
    if (body === '' || !body) {
      vm.preview_body = '';
      return false;
    }
    if (body === Preview.old_text) {
      return false;
    }

    if (vm.processing) {
      return false;
    }
    vm.processing = true;

    var promise = Preview.get_preview(vm.project, body);
    promise.success(function(response) {
      vm.preview_body = response.html;
      Preview.old_text = body;
    }).error(function(response) {
      vm.preview_body = 'Error :(';
    });

    vm.processing = false;
    return false;
  };

  vm.toggleLabel = function(label) {
    if (vm.action === 'show') {
      if (vm.processing_issue_labels) {
        return false;
      }
      vm.processing_issue_labels = true;
    }

    label.selected = !label.selected;
    if (label.selected) {
      label.style = label.default_style;
      label.selected_id = label.id;
    } else {
      label.selected_id = null;
      label.style = {};
    }

    if (vm.action === 'show') {
      vm.updateIssue('labels', { label: label });
    }
    return true;
  };

  vm.getAssignees = function(val) {
    vm.processing_issue_assignee = true;
    var promise = Issue.getAssignees(vm.project, val);
    promise.then(function(response) {
      vm.processing_issue_assignee = false;
      return response.data;
    });
  };

  vm.selectAssignee = function(item, model, label) {
    if (vm.action === 'show') {
      if (vm.processing_issue_assignee) {
        return false;
      }
      vm.processing_issue_assignee = true;
    }

    vm.assignee = item;

    if (vm.action === 'show') {
      vm.updateIssue('assignee', { assignee: vm.assignee });
    }
    vm.toggle_manage_assignee = false;
    return false;
  };

  vm.removeAssignee = function() {
    if (!confirmMessage.show()) {
      return false;
    }
    if (vm.action === 'show') {
      if (vm.processing_issue_assignee) {
        return false;
      }
      vm.processing_issue_assignee = true;
    }

    vm.assignee = {};

    if (vm.action === 'show') {
      vm.updateIssue('assignee', { assignee: vm.assignee });
    }
    vm.toggle_manage_assignee = false;
    return false;
  };

  vm.updateStatus = function() {
    if (vm.action !== 'show') {
      return false;
    }
    if (vm.processing_issue_status) {
      return false;
    }
    vm.processing_issue_status = true;
    vm.updateIssue('status', { status: vm.status });
    return false;
  };

  vm.updateIssue = function(kind, extra) {
    if (extra === undefined) {
      extra = {};
    }

    var promise = Issue.update(vm.project, vm.serial_id, kind, extra);
    promise.then(function(response) {
      updateIssueFromResponse(response);
      if (kind === 'title_body') {
        vm.edit = false;
      }
      if (vm.action === 'show' && vm.processing_issue_assignee) {
        vm.processing_issue_assignee = false;
      }
      if (vm.action === 'show' && vm.processing_issue_labels) {
        vm.processing_issue_labels = false;
      }
      if (vm.action === 'show' && vm.processing_issue_status) {
        vm.processing_issue_status = false;
      }
    });
    return false;
  };

  $rootScope.$on("updateLabels", function(event, args) {
    getLabels();
  });

  var init = function(dataservice) {
    vm.project = dataservice.project;
    vm.serial_id = dataservice.serial_id;
    vm.labels = dataservice.labels;
    vm.action = dataservice.action;
    vm.assignee = dataservice.assignee;
    vm.status = dataservice.status;

    vm.toggle_manage_assignee = false;
    vm.processing = false;

    vm.processing_issue_labels = false;
    vm.processing_issue_assignee = false;

    updateStatusCLass();
  };

  init(dataservice);
  return true;
};

angular
  .module("RosaABF")
  .controller("IssueController", IssueController);

IssueController.$inject = [
  'IssueInitializer',
  '$http',
  'Issue',
  '$rootScope',
  'Preview',
  'Label',
  'confirmMessage'
];

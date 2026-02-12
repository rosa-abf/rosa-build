var issueService = function($http) {

  var getFormParams = function(kind, extra) {
    if (extra === undefined) {
      extra = {};
    }

    if (kind === 'title_body') {
      return {
        issue: {
          title: $('#issue_title').val(),
          body: $('#issue-body').val()
        }
      };
    } else if (kind === 'labels') {
      var is_destroy;
      if (extra.label.selected === false) {
        is_destroy = '1';
      } else {
        is_destroy = '0';
      }
      return {
        issue: {
          labelings_attributes: [
            {
              id: extra.label.labeling_id,
              label_id: extra.label.id,
              _destroy: is_destroy
            }
          ]
        }
      };
    } else if (kind === 'assignee') {
      return {
        issue: {
          assignee_id: extra.assignee.id
        }
      };
    } else if (kind === 'status') {
      var status;
      if (extra.status.name !== 'closed') {
        status = 'closed';
      } else {
        status = 'open';
      }
      return {
        issue: {
          status: status
        }
      };
    }
  };

  return {
    getIssues: function(project, filter) {
      var params = {
        kind: filter.kind,
        filter: filter.name,
        sort: filter.sort,
        direction: filter.sort_direction,
        status: filter.status,
        labels: filter.labels,
        page: filter.page
      };

      var path = Routes.project_issues_path(project, params);
      return $http.get(path);
    },

    getAssignees: function(project, val) {
      var path = Routes.search_collaborators_project_issues_path(project, { search_user: val });
      return $http.get(path);
    },

    update: function(project, id, kind, extra) {
      if (extra === undefined) {
        extra = {};
      }

      var params = getFormParams(kind, extra);
      var path = Routes.project_issue_path(project, id);
      return $http.put(path, params);
    }
  };
};

angular
  .module("RosaABF")
  .factory("Issue", issueService);

issueService.$inject = ['$http'];

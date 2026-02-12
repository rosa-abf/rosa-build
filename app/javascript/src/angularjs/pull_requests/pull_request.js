ApiPullRequestService = function($resource, $http) {

  var getPath = function(pull, kind) {
    var name_with_owner = pull.owner + '/' + pull.project;
    var params;

    switch (kind) {
    case 'activity':
    params = { get_activity: true };
    break;
    case 'diff':
    params = { get_diff: true };
    break;
    case 'commits':
    params = { get_commits: true };
    break;
    }

    return Routes.project_pull_request_path(name_with_owner, pull.serial_id, params);
  };

  var PullRequestResource = $resource("/:owner/:project/pull_requests/:serial_id?format=json", {
    owner: "@pull_request.to_ref.project.owner_uname",
    project: "@pull_request.to_ref.project.name",
    serial_id: "@pull_request.number"
  }, {
    update: {
      method: "PUT",
      isArray: false
    },
    merge: {
      url: "/:owner/:project/pull_requests/:serial_id/merge",
      format: "json",
      method: "PUT",
      isArray: false
    }
  });

  var get_activity = function(params) {
    var path = getPath(params, 'activity');
    return $http.get(path);
  };

  var get_diff = function(params) {
    var path = getPath(params, 'diff');
    return $http.get(path);
  };

  var get_commits = function(params) {
    var path = getPath(params, 'commits');
    return $http.get(path);
  };

  return {
    resource: PullRequestResource,
    get_activity: get_activity,
    get_diff: get_diff,
    get_commits: get_commits
  };
};

angular
  .module("RosaABF")
  .factory("ApiPullRequest", ApiPullRequestService);

ApiPullRequestService.$inject = ['$resource', '$http'];

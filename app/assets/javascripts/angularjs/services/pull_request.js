var ApiPullRequest = function($resource) {

  var PullRequest = $resource(
    '/api/v1/projects/:project_id/pull_requests/:serial_id.json', {},
    {
      get:    {method:'GET', isArray: false},
      update: {
        method:'PUT',
        params:{
          project_id:'@pull_request.to_ref.project.id',
          serial_id: '@pull_request.number'
        }, isArray : false
      }
    }
  );

  // var queryPullRequest = function(project_id, serial_id, next) {
  //   PullRequest.get({project_id: project_id, serial_id: serial_id}, function(results) {
  //     next(results.pull_request);
  //   });
  // }

  // var queryUpdatePullRequest = function(project_id, serial_id, params, next) {
  //   PullRequest.put({
  //     project_id:   project_id,
  //     serial_id:    serial_id,
  //     pull_request: params
  //   }, function(results) {
  //     next(results);
  //   });
  // }

  return {
    // pullRequest : queryPullRequest,
    // updatePullRequest : queryUpdatePullRequest,
    resource : PullRequest
  }
}

RosaABF.factory("ApiPullRequest", ApiPullRequest);
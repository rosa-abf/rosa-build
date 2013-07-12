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
      },
      merge: {
        url:    '/api/v1/projects/:project_id/pull_requests/:serial_id/merge.json',
        method: 'PUT',
        params: {
          project_id:'@pull_request.to_ref.project.id',
          serial_id: '@pull_request.number'
        }, isArray:  false
      }
    }
  );

  return {
    resource : PullRequest
  }
}

RosaABF.factory("ApiPullRequest", ApiPullRequest);
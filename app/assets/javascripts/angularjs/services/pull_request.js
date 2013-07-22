RosaABF.factory("ApiPullRequest", ['$resource', function($resource) {

  var PullRequestResource = $resource(
    '/api/v1/projects/:project_id/pull_requests/:serial_id.json',
    {
      project_id: '@pull_request.to_ref.project.id',
      serial_id:  '@pull_request.number'
    },
    {
      update: {
        method: 'PUT',
        isArray :  false
      },
      merge: {
        url:    '/api/v1/projects/:project_id/pull_requests/:serial_id/merge.json',
        method: 'PUT',
        isArray:   false
      }
    }
  );

  return {
    resource : PullRequestResource
  }
}]);
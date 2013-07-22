RosaABF.factory("ApiProject", ['$resource', function($resource) {

  var ProjectResource = $resource(
    '/api/v1/projects/:id.json',
    {id: '@project.id'},
    {
      refs: {
        url:    '/api/v1/projects/:id/refs_list.json',
        method: 'GET',
        isArray : false
      },
      delete_branch: {
        url:    '/:owner/:project/branches/:ref',
        method: 'DELETE',
        isArray : false
      },
      restore_branch: {
        url:    '/:owner/:project/branches/:ref', // ?sha=<sha>
        method: 'PUT',
        isArray : false
      },
      create_branch: {
        url:    '/:owner/:project/branches', // ?new_ref=<new_ref>&from_ref=<from_ref>
        method: 'POST',
        isArray : false
      }
    }
  );

  return {
    resource  : ProjectResource,
    singleton : {
      project : {
        branches_count : 0
      }
    }
  }
}]);
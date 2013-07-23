RosaABF.factory("ApiProject", ['$resource', function($resource) {

  var ProjectResource = $resource(
    '/:owner/:project',
    {owner: '@project.owner.uname', project: '@project.name'},
    {
      // refs: {
      //   url:    '/api/v1/projects/:id/refs_list.json',
      //   method: 'GET',
      //   isArray : false
      // },
      update: {
        url:      '/api/v1/projects/:id.json',
        method:   'PUT',
        isArray:  false
      },
      tags: {
        url:    '/:owner/:project/tags',
        method: 'GET',
        isArray : false
      },
      branches: {
        url:    '/:owner/:project/branches',
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
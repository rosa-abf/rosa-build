RosaABF.factory("ApiProject", ['$resource', function($resource) {

  var ProjectResource = $resource(
    '/:owner/:project',
    {owner: '@project.owner.uname', project: '@project.name'},
    {
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
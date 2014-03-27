RosaABF.factory("ApiProject", ['$resource', function($resource) {

  var ProjectResource = $resource(
    '/:owner/:project?format=json',
    {owner: '@project.owner.uname', project: '@project.name'},
    {
      tags: {
        url:    '/:owner/:project/tags',
        format: 'json',
        method: 'GET',
        isArray : false
      },
      branches: {
        url:    '/:owner/:project/branches',
        format: 'json',
        method: 'GET',
        isArray : false
      },
      delete_branch: {
        url:    '/:owner/:project/branches/:ref',
        format: 'json',
        method: 'DELETE',
        isArray : false
      },
      restore_branch: {
        url:    '/:owner/:project/branches/:ref', // ?sha=<sha>
        format: 'json',
        method: 'PUT',
        isArray : false
      },
      create_branch: {
        url:    '/:owner/:project/branches', // ?new_ref=<new_ref>&from_ref=<from_ref>
        format: 'json',
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
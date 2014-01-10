RosaABF.factory("ApiProject", ['$resource', function($resource) {

  var ProjectResource = $resource(
    '/:owner/:project?format=json',
    {owner: '@project.owner.uname', project: '@project.name'},
    {
      tags: {
        url:    '/:owner/:project/tags.json',
        method: 'GET',
        isArray : false
      },
      branches: {
        url:    '/:owner/:project/branches.json',
        method: 'GET',
        isArray : false
      },
      delete_branch: {
        url:    '/:owner/:project/branches/:ref.json',
        method: 'DELETE',
        isArray : false
      },
      restore_branch: {
        url:    '/:owner/:project/branches/:ref.json', // ?sha=<sha>
        method: 'PUT',
        isArray : false
      },
      create_branch: {
        url:    '/:owner/:project/branches.json', // ?new_ref=<new_ref>&from_ref=<from_ref>
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
RosaABF.factory('ApiCollaborator', ['$resource', function($resource) {

  var CollaboratorResource = $resource(
    '/:owner/:project/collaborators/:id?format=json',
    {
      owner: '@project.owner_uname',
      project: '@project.name',
      id: '@id'
    },
    {
      update: {
        method: 'PUT',
        isArray :  false
      },
      find: {
        url:    '/:owner/:project/collaborators/find.json',
        method: 'GET',
        isArray :  true
      }
    }
  );

  return {
    resource : CollaboratorResource
  }
}]);
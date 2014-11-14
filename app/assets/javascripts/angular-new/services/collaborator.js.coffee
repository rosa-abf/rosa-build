collaboratorService = ($http) ->
  {
    find: (name_with_owner, val) ->
      path = Routes.find_project_collaborators_path(
        {
          name_with_owner: name_with_owner,
          term:            val
        }
      )

      $http.get(path).then (response) ->
        response.data

    add: (name_with_owner, selected, role, project_id) ->
      path = Routes.project_collaborators_path(
        {
          name_with_owner: name_with_owner,
          collaborator: {
            actor_id:   selected.actor_id
            actor_type: selected.actor_type
            role:       role
            project_id: project_id
          }
        }
      )

      $http.post(path)
    }

angular
  .module("RosaABF")
  .factory "Collaborator", collaboratorService

collaboratorService.$inject = ['$http']

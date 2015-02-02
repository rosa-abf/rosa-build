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

    remove: (name_with_owner, member_id) ->
      path = Routes.project_collaborator_path(name_with_owner, member_id)

      $http.delete(path)

    update: (name_with_owner, member) ->
      path = Routes.project_collaborator_path(
        name_with_owner,
        member.id,
        {
          collaborator: { role: member.role }
        }
      )
      $http.put(path)
    }

angular
  .module("RosaABF")
  .factory "Collaborator", collaboratorService

collaboratorService.$inject = ['$http']

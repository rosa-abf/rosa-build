var collaboratorService = function($http) {
  return {
    find: function(name_with_owner, val) {
      var path = Routes.find_project_collaborators_path({
                                                        name_with_owner: name_with_owner,
                                                        term: val
      });

      return $http.get(path).then(function(response) {
        return response.data;
      });
    },

    add: function(name_with_owner, selected, role, project_id) {
      var path = Routes.project_collaborators_path({
                                                   name_with_owner: name_with_owner,
                                                   collaborator: {
                                                     actor_id: selected.actor_id,
                                                     actor_type: selected.actor_type,
                                                     role: role,
                                                     project_id: project_id
                                                   }
      });

      return $http.post(path);
    },

    remove: function(name_with_owner, member_id) {
      var path = Routes.project_collaborator_path(name_with_owner, member_id);
      return $http.delete(path);
    },

    update: function(name_with_owner, member) {
      var path = Routes.project_collaborator_path(
                                                  name_with_owner,
                                                  member.id,
                                                  {
                                                    collaborator: { role: member.role }
                                                  }
                                                 );
      return $http.put(path);
    }
  };
};

angular
  .module("RosaABF")
  .factory("Collaborator", collaboratorService);

collaboratorService.$inject = ['$http'];

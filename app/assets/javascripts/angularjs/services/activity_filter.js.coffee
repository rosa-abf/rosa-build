ActivityFilterService = ($http) ->
  get_owners: (val) ->
    path = Routes.get_owners_list_path(
      {
        term: val
      }
    )

    $http.get(path).then (response) ->
      response.data
  get_project_names: (owner, val) ->
    path = Routes.get_project_names_list_path(
      {
        owner_uname: owner
        term: val
      }
    )

    $http.get(path).then (response) ->
      response.data


angular
  .module("RosaABF")
  .factory "ActivityFilter", ActivityFilterService

ActivityFilterService.$inject = ['$http']

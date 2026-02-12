var ActivityFilterService = function($http) {
  return {
    get_owners: function(val) {
      var path = Routes.get_owners_list_path({
                                             term: val
      });

      return $http.get(path).then(function(response) {
        return response.data;
      });
    },

    get_project_names: function(owner, val) {
      var path = Routes.get_project_names_list_path({
                                                    owner_uname: owner,
                                                    term: val
      });

      return $http.get(path).then(function(response) {
        return response.data;
      });
    }
  };
};

angular
  .module("RosaABF")
  .factory("ActivityFilter", ActivityFilterService);

ActivityFilterService.$inject = ['$http'];

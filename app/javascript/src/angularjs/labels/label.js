var labelService = function($http) {
  return {
    default_colors: [
      '0054a6',
      '00a651',
      'ed1c24',
      'e65c00',
      '9e005d',
      '464646',
      '8c6239'
    ],

    add: function(project, label) {
      var params = {
        name: label.name,
        color: label.color
      };

      var path = Routes.create_label_project_issues_path(project, params);
      return $http.post(path);
    },

    update: function(project, label) {
      var params = {
        name: label.name,
        color: label.color
      };

      var path = Routes.project_issues_update_label_path(project, label.id, params);
      return $http.post(path);
    },

    remove: function(project, label) {
      var path = Routes.project_issues_delete_label_path(project, label.id);
      return $http.post(path);
    },

    get_labels: function(project) {
      var path = Routes.project_labels_path(project);
      return $http.get(path);
    }
  };
};

angular
  .module("RosaABF")
  .factory("Label", labelService);

labelService.$inject = ['$http'];

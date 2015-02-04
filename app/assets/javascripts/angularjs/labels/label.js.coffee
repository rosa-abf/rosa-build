labelService = ($http) ->
  {
    default_colors: [
                      '0054a6'
                      '00a651'
                      'ed1c24'
                      'e65c00'
                      '9e005d'
                      '464646'
                      '8c6239'
                    ]

    add: (project, label) ->
      params =  {
                  name:  label.name
                  color: label.color
                }

      path = Routes.create_label_project_issues_path(project, params)
      $http.post(path)

    update: (project, label) ->
      params =  {
                  name:  label.name
                  color: label.color
                }

      path = Routes.project_issues_update_label_path(project, label.id, params)
      $http.post(path)

    remove: (project, label) ->
      path = Routes.project_issues_delete_label_path(project, label.id)
      $http.post(path)

    get_labels: (project) ->
      path = Routes.project_labels_path(project)
      $http.get(path)
  }

angular
  .module("RosaABF")
  .factory "Label", labelService

labelService.$inject = ['$http']

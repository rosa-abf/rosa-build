RosaABF.controller 'RepositoryProjectsController', ['$scope', '$http', '$location', 'confirmMessage', ($scope, $http, $location, confirmMessage) ->

  $scope.added          = $('#added').val()
  $scope.platform_id    = $('#platform_id').val()
  $scope.repository_id  = $('#repository_id').val()
  $scope.processing     = true
  $scope.projects       = []
  $scope.total_items    = null

  # Fixes: redirect to page after form submit
  $("#search_projects_form").on 'submit', ->
    false

  $scope.refresh = ->
    $scope.processing = true

    params  =
      added:        $scope.added
      owner_name:   $('#project_owner').val()
      project_name: $('#project_name').val()
      page:         $('#page').val()
      format:       'json'

    path = Routes.projects_list_platform_repository_path $scope.platform_id, $scope.repository_id
    $http.get(path, params: params).success (data) ->
      $scope.projects    = data.projects
      $scope.total_items = data.total_items
      $scope.processing  = false
    .error ->
      $scope.projects    = []
      $scope.processing  = false

    true

  $scope.search = ->
    params =
      owner_name:   $('#project_owner').val()
      project_name: $('#project_name').val()
    $location.search(params)

  $scope.$on '$locationChangeSuccess', (event) ->
    $scope.updateParams()
    $scope.refresh()

  $scope.updateParams = ->
    params = $location.search()
    $('#project_owner').val(params['owner_name'])
    $('#project_name').val(params['project_name'])
    $('#page').val(params['page'])

  $scope.goToPage = (number) ->
    $location.search('page', number)

  $scope.removeProject = (project) ->
    return false unless confirmMessage.show()
    $scope.processing = true
    $http.delete(project.remove_path).success (data) ->
      Notifier.success(data.message)
      $scope.projects = _.reject($scope.projects, (pr) ->
       return pr.id is project.id
      )
      $scope.processing  = false
]
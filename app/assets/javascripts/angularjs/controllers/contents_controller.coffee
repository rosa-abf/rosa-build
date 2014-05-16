RosaABF.controller 'ContentsController', ['$scope', '$http', ($scope, $http) ->

  $scope.platform   = null
  $scope.path       = null
  $scope.processing = true
  $scope.contents   = []

  $scope.init = (platform, path)->
    $scope.platform = platform
    $scope.path     = path
    $scope.platform_path = Routes.platform_contents_path($scope.platform)
    $scope.refresh()

  $scope.refresh = (path) ->
    $scope.processing = true
    path = $scope.path unless path
    params  =
      platform_id:  $scope.platform
      path:         path
      term:         $('#term').val()
      format:       'json'

    $http.get(Routes.platform_contents_path(params)).success( (data) ->
      $scope.contents   = data.contents
      $scope.path       = data.path
      $scope.processing = false
    ).error( ->
      $scope.contents   = []
      $scope.processing = false
    )

  $scope.open = (content) ->
    if content.is_folder
      $scope.refresh(content.path)

  $scope.destroy  = (content) ->
    params  =
      platform_id:  $scope.platform
      path:         content.path
      format:       'json'

    content.processing = true
    $http.delete(Routes.platform_content_path(params)).success( ->
      $scope.refresh()
    ).error( ->
      $scope.refresh()
    )

    # $http.delete(
    #   Routes.project_path($scope.name_with_owner),
    #   {file: {autostart_status: $scope.autostart_status}, format: 'json'}
    # );

]
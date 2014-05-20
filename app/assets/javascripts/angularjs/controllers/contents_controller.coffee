RosaABF.controller 'ContentsController', ['$scope', '$http', '$location', ($scope, $http, $location) ->

  $scope.platform   = $('#platform_name').val()
  $scope.processing = true
  $scope.contents   = []
  $scope.folders    = []

  # Fixes: redirect to page after form submit
  $("#search_contents_form").on 'submit', ->
    false

  $scope.refresh = ->
    $scope.processing = true

    params  =
      platform_id:  $scope.platform
      path:         $('#path').val()
      term:         $('#term').val()
      format:       'json'

    $http.get(Routes.platform_contents_path(params)).success( (data) ->
      $scope.folders    = data.folders
      $scope.contents   = data.contents
      $scope.back       = data.back
      $scope.processing = false
    ).error( ->
      $scope.contents   = []
      $scope.processing = false
    )
    true

  $scope.open = (content) ->
    return if $scope.processing
    if $.type(content) == 'string'
      $location.search('path', content)
    else if content.is_folder
      $location.search('path', content.subpath)

  $scope.destroy  = (content) ->
    params  =
      path:   content.subpath
      format: 'json'

    content.processing = true
    $http.delete(Routes.remove_file_platform_contents_path($scope.platform, params)).success( ->
      $scope.refresh()
    ).error( ->
      $scope.refresh()
    )
    true

  $scope.search = ->
    $location.search('term', $('#term').val())

  $scope.$on '$locationChangeSuccess', (event) ->
    $scope.updateParams()
    $scope.refresh()

  $scope.updateParams = ->
    params = $location.search()
    $('#path').val(params['path'])
    $('#term').val(params['term'])

]
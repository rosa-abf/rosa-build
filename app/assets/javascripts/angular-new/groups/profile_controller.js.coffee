RosaABF.controller 'Groups::ProfileController', ['$scope', '$http', '$location', ($scope, $http, $location) ->

  $scope.group       = $('#group_uname').val()
  $scope.processing  = true
  $scope.projects    = []
  $scope.page        = null
  $scope.total_items = null

  $scope.term        = null
  $scope.visibility  = 'open'

  # Fixes: redirect to page after form submit
  $("#search_projects_form").on 'submit', ->
    false

  $scope.refresh = ->
    $scope.processing = true

    params  =
      term:         $scope.term
      visibility:   $scope.visibility
      page:         $scope.page
      format:       'json'

    $http.get Routes.user_path($scope.group), params: params
    .success (data) ->
      $scope.projects    = data.projects
      $scope.total_items = data.total_items
      $scope.processing  = false
    .error ->
      $scope.projects    = []
      $scope.processing  = false

    true

  $scope.search = ->
    params =
      term:       $scope.term
      visibility: $scope.visibility
    $location.search params

  $scope.$on '$locationChangeSuccess', (event) ->
    $scope.updateParams()
    $scope.refresh()

  $scope.updateParams = ->
    params = $location.search()
    $scope.term       = params['term']
    $scope.visibility = params['visibility'] if params['visibility']
    $scope.page       = params['page']

  $scope.goToPage = (number) ->
    $location.search 'page', number

]
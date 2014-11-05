RosaABF.controller 'BuildListController', ['$scope', '$http', '$timeout', 'SoundNotificationsHelper', ($scope, $http, $timeout, SoundNotificationsHelper) ->

  $scope.advisoriable_types = null

  $scope.id                 = $('#build_list_id').val()
  $scope.build_list         = null
  $scope.subject            = {} # See: shared/build_results
  $scope.attach_advisory    = 'no'
  # Statuses: advisory_not_found, server_error, continue_input
  $scope.search_status      = 'continue_input'
  $scope.term               = ''
  $scope.advisory           = null
  $scope.update_type_errors = null

  $scope.getBuildList = ->
    $http.get Routes.build_list_path($scope.id, {format: 'json'})
    .success (results) ->
      build_list = new BuildList(results.build_list)
      if $scope.build_list && $scope.build_list.status != build_list.status
        SoundNotificationsHelper.buildStatusChanged()
      $scope.build_list = $scope.subject = build_list

  $scope.canRefresh = ->
    return false  if $scope.attach_advisory != 'no'
    return true   unless $scope.build_list

    show_dependent_projects = _.find $scope.build_list.packages, (p) ->
      p.show_dependent_projects

    return false if show_dependent_projects

    statuses = [
      666,  # BuildList::BUILD_ERROR
      5000, # BuildList::BUILD_CANCELED
      6000, # BuildList::BUILD_PUBLISHED
      8000, # BuildList::FAILED_PUBLISH
      9000, # BuildList::REJECTED_PUBLISH
    ]

    if !_.contains(statuses, $scope.build_list.status)
      true
    else
      false

    # if (!(
    #   $scope.build_list.status == <%=BuildList::BUILD_PUBLISHED%> ||
    #   $scope.build_list.status == <%=BuildList::REJECTED_PUBLISH%> ||
    #   $scope.build_list.status == <%=BuildList::FAILED_PUBLISH%> ||
    #   $scope.build_list.status == <%=BuildList::BUILD_CANCELED%> ||
    #   $scope.build_list.status == <%=BuildList::BUILD_ERROR%>
    # )) { return true; }

  $scope.cancelRefresh = null
  $scope.refresh = ->
    if $scope.canRefresh()
      $scope.getBuildList()
    $scope.cancelRefresh = $timeout($scope.refresh, 10000)

  $scope.refresh()

  $scope.search = ->
    params =
      query:    $scope.term
      bl_type:  $scope.build_list.update_type
      format:   'json'

    $http.get Routes.search_advisories_path(params)
    .success (results) ->
        $scope.search_status    = 'continue_input'
        $scope.advisory         = results
        $('#attach_advisory').find('.advisory_id').val($scope.advisory.advisory_id)
    .error (data, status, headers, config) ->
        $scope.search_status  = status == 404 ? 'advisory_not_found' : 'server_error'
        $scope.advisory       = null
        $('#attach_advisory').find('.advisory_id').val('')

  $scope.updateTypeChanged = ->
    if _.contains($scope.advisoriable_types, $scope.build_list.update_type)
      if $scope.advisory || $scope.term.length > 0
        $scope.search()
    else
      $scope.attach_advisory = 'no'

    $scope.updateUpdateType()

  $scope.attachAdvisoryChanged = ->
    unless _.contains($scope.advisoriable_types, $scope.build_list.update_type)
      $scope.build_list.update_type = $scope.advisoriable_types[0]
      $scope.updateUpdateType()

    $('#build_list_update_type .nonadvisoriable').attr('disabled', ($scope.attach_advisory != 'no'))

  $scope.updateUpdateType = ->
    params =
      update_type:  $scope.build_list.update_type
      format:       'json'
    $http.put Routes.update_type_build_list_path($scope.id), params
    .success (results) ->
      $scope.update_type_errors = null
      $timeout ->
        $('#build_list_update_type').effect('highlight', {}, 1000)
      , 100
    .error (data, status, headers, config) ->
      $scope.update_type_errors = data.message

]
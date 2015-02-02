LabelsController = (dataservice, $http, Label, $rootScope, $scope, confirmMessage) ->

  $scope.$watch (->
    vm.label.color
  ), () ->
    vm.label.color = vm.label.color.replace(/[^a-f0-9]/gmi,'') if vm.label.color

  vm = this


  vm.colorClass = (color) ->
    if vm.label.color == color
      'fa-check-circle'
    else
      'fa-circle'

  vm.colorStyle = (color) ->
    color: '#'+color

  vm.colorPreviewStyle = () ->
    color:      '#FFF'
    background: '#'+vm.label.color

  vm.selectCurrentLabel = (l) ->
    vm.label.id     = l.id
    vm.label.name   = l.name
    vm.label.color  = l.color
    vm.is_new_label = false
    false

  vm.saveLabel = () ->
    return false unless vm.label.name && vm.label.color

    if vm.is_new_label
      promise = Label.add(vm.project, vm.label)
    else
      promise = Label.update(vm.project, vm.label)
    promise.success( (data) ->
      vm.labels = data
      vm.errors = []
      $rootScope.$broadcast('updateLabels')
    ).error( (data) ->
      vm.errors = data
    )

    false

  vm.removeLabel = (l) ->
    return false unless confirmMessage.show()
    promise = Label.remove(vm.project, l)
    promise.success (data) ->
      $rootScope.$broadcast('updateLabels')

    false


  init = (dataservice) ->
    vm.project                   = dataservice.project
    vm.labels                    = dataservice.labels
    vm.is_collapsed_manage_block = true

    vm.default_colors            = Label.default_colors
    vm.label                     = {
                                     id:    null
                                     name:  null
                                     color: vm.default_colors[0]
                                   }
    vm.is_new_label              = true
    vm.processing                = false

  init(dataservice)
  true

angular
  .module("RosaABF")
  .controller "LabelsController", LabelsController

LabelsController.$inject = [
                             'LabelsInitializer'
                             '$http'
                             'Label'
                             '$rootScope'
                             '$scope'
                             'confirmMessage'
                           ]

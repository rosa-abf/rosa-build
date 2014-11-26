IssueController = (dataservice, $http, Issue, $rootScope, Preview) ->

  vm = this

  vm.previewBody = ->
    if vm.body is '' or !vm.body
      vm.preview_body = ''
      return false
    if vm.body is Preview.old_text
      return false

    vm.processing = true

    promise = Preview.get_preview(vm.project, vm.body)
    promise.success( (response) ->
      vm.preview_body  = response
      Preview.old_text = vm.body
    ).error( (response) ->
      vm.preview_body = 'Error :('
    )

    vm.processing = false
    false

  init = (dataservice) ->
    vm.project = dataservice.project
    vm.labels  = dataservice.labels
    vm.processing = false

  init(dataservice)
  true

angular
  .module("RosaABF")
  .controller "IssueController", IssueController

IssueController.$inject = ['IssueInitializer', '$http', 'Issue', '$rootScope', 'Preview']

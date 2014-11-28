IssueController = (dataservice, $http, Issue, $rootScope, Preview, Label) ->

  updateIssueFromResponse = (response) ->
    $('#issue_title_text').html(response.data.title)
    $('#issue_body_text').html(response.data.body)

  getLabels = ->
    promise = Label.get_labels(vm.project)
    promise.then (response) ->
      old_labels = vm.labels
      vm.labels = response.data
      _.each(vm.labels, (l) ->
        _.each(old_labels, (ol) ->
          if l.id is ol.id
            l.selected    = ol.selected
            l.style       = ol.style
            l.selected_id = ol.selected_id
        )
      )
    true

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

  vm.toggleLabel = (label) ->
    label.selected = !label.selected
    if label.selected
      label.style       = label.default_style
      label.selected_id = label.id
    else
      label.selected_id = null
      label.style = {}
    vm.updateIssue('labels', {id: label.id, selected: label.selected}) if action is 'show'
    true

  vm.getAssignees = (val) ->
    promise = Issue.getAssignees(vm.project, val)
    promise.then (response) ->
      response.data

  vm.selectAssignee = (item, model, label) ->
    vm.assignee = item
    vm.toggle_manage_assignee = false
    false

  vm.removeAssignee = () ->
    vm.assignee = {}
    vm.toggle_manage_assignee = false
    false

  vm.updateIssue = (kind) ->
    promise = Issue.update(vm.project, vm.serial_id, kind)
    promise.then (response) ->
      updateIssueFromResponse(response)
      vm.edit = false if kind is 'title_body'
    false

  $rootScope.$on "updateLabels", (event, args) ->
    getLabels()

  init = (dataservice) ->
    vm.project                = dataservice.project
    vm.serial_id              = dataservice.serial_id
    vm.labels                 = dataservice.labels
    vm.action                 = dataservice.action
    vm.assignee               = dataservice.assignee

    vm.toggle_manage_assignee = false
    vm.processing             = false

  init(dataservice)
  true

angular
  .module("RosaABF")
  .controller "IssueController", IssueController

IssueController.$inject = [
                            'IssueInitializer'
                            '$http'
                            'Issue'
                            '$rootScope'
                            'Preview'
                            'Label'
                          ]

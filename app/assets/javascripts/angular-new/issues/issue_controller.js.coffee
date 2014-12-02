IssueController = (dataservice, $http, Issue, $rootScope, Preview, Label, confirmMessage) ->

  updateIssueFromResponse = (response) ->
    $('#issue_title_text').html(response.data.title)
    $('#issue_body_text').html(response.data.body)
    vm.assignee = response.data.assignee
    vm.labels   = response.data.labels
    vm.status   = response.data.status

    updateStatusCLass()

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

  updateStatusCLass = ->
    if vm.status.name is 'open' or vm.status.name is 'reopen'
      vm.issue_status_class = 'btn-primary'
    else
      vm.issue_status_class = 'btn-danger'


  vm = this

  vm.previewBody = ->
    if vm.body is '' or !vm.body
      vm.preview_body = ''
      return false
    if vm.body is Preview.old_text
      return false

    return false if vm.processing
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
    if vm.action is 'show'
      return false if vm.processing_issue_labels
      vm.processing_issue_labels = true

    label.selected = !label.selected
    if label.selected
      label.style       = label.default_style
      label.selected_id = label.id
    else
      label.selected_id = null
      label.style = {}

    if vm.action is 'show'
      vm.updateIssue('labels', label: label)
    true

  vm.getAssignees = (val) ->
    vm.processing_issue_assignee = true
    promise = Issue.getAssignees(vm.project, val)
    promise.then (response) ->
      vm.processing_issue_assignee = false
      response.data

  vm.selectAssignee = (item, model, label) ->
    if vm.action is 'show'
      return false if vm.processing_issue_assignee
      vm.processing_issue_assignee = true

    vm.assignee = item

    if vm.action is 'show'
      vm.updateIssue('assignee', assignee: vm.assignee)
    vm.toggle_manage_assignee    = false
    false

  vm.removeAssignee = () ->
    return false unless confirmMessage.show()
    if vm.action is 'show'
      return false if vm.processing_issue_assignee
      vm.processing_issue_assignee = true

    vm.assignee = {}

    if vm.action is 'show'
      vm.updateIssue('assignee', assignee: vm.assignee)
    vm.toggle_manage_assignee    = false
    false

  vm.updateStatus = ->
    return false if vm.action isnt 'show'
    return false if vm.processing_issue_status
    vm.processing_issue_status = true
    vm.updateIssue('status', status: vm.status)
    false

  vm.updateIssue = (kind, extra = {}) ->
    promise = Issue.update(vm.project, vm.serial_id, kind, extra)
    promise.then (response) ->
      updateIssueFromResponse(response)
      vm.edit = false if kind is 'title_body'
      if vm.action is 'show' and vm.processing_issue_assignee
        vm.processing_issue_assignee = false
      if vm.action is 'show' and vm.processing_issue_labels
        vm.processing_issue_labels = false
      if vm.action is 'show' and vm.processing_issue_status
        vm.processing_issue_status = false
    false


  $rootScope.$on "updateLabels", (event, args) ->
    getLabels()

  init = (dataservice) ->
    vm.project   = dataservice.project
    vm.serial_id = dataservice.serial_id
    vm.labels    = dataservice.labels
    vm.action    = dataservice.action
    vm.assignee  = dataservice.assignee
    vm.status    = dataservice.status

    vm.toggle_manage_assignee  = false
    vm.processing              = false

    vm.processing_issue_labels   = false
    vm.processing_issue_assignee = false

    updateStatusCLass()

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
                            'confirmMessage'
                          ]

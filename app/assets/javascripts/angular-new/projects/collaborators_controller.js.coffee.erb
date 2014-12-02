CollaboratorsController = (dataservice, Collaborator, $http, confirmMessage) ->
  vm = this

  vm.new_role = 'reader'

  vm.isDisabledDeleteAllButton = ->
    is_selected = true
    result = _.select(vm.collaborators, (c) ->
      is_selected = false if c.check_delete
    )
    is_selected

  vm.getCollaborators = (val) ->
    return [] if val.length <= 2
    Collaborator.find(vm.name_with_owner, val)

  vm.selectCollaborator = (item, model, label) ->
    vm.selected_new_collaborator = item
    false

  vm.addCollaborator = ->
    promise = Collaborator.add(vm.name_with_owner,
                               vm.selected_new_collaborator,
                               vm.new_role,
                               vm.project_id)
    promise.success (data) ->
      vm.collaborators.push data

    vm.selected_new_collaborator = null
    false

  vm.removeCollaborator = (member) ->
    return false unless confirmMessage.show()
    promise = Collaborator.remove(vm.name_with_owner, member.id)
    promise.success (data) ->
      vm.collaborators = _.reject(vm.collaborators, (c) ->
        c.id is member.id
      )
    false

  vm.removeCollaborators = ->
    return false unless confirmMessage.show()
    _.each(vm.collaborators, (c) ->
      vm.removeCollaborator(c) if c.check_delete
    )
    false

  vm.updateCollaborator = (member) ->
    return false unless confirmMessage.show()
    Collaborator.update(vm.name_with_owner, member)
    false

  init = (dataservice) ->
    vm.name_with_owner = dataservice.name_with_owner
    vm.project_id      = dataservice.project_id

    vm.collaborators   = dataservice.collaborators

  init(dataservice)
  return true


angular
  .module("RosaABF")
  .controller "CollaboratorsController", CollaboratorsController

CollaboratorsController.$inject = [
                                    'CollaboratorsInitializer'
                                    'Collaborator'
                                    '$http'
                                    'confirmMessage'
                                  ]

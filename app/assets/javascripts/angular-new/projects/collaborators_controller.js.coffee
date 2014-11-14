CollaboratorsController = (dataservice, Collaborator, $http) ->
  vm = this

  vm.new_role = 'reader'

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

  init = (dataservice) ->
    vm.name_with_owner = dataservice.name_with_owner
    vm.project_id      = dataservice.project_id

    vm.collaborators   = dataservice.collaborators

  init(dataservice)
  return true


angular
  .module("RosaABF")
  .controller "CollaboratorsController", CollaboratorsController

CollaboratorsController.$inject = ['CollaboratorsInitializer', 'Collaborator', '$http']

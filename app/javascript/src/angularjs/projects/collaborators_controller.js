var CollaboratorsController = function(dataservice, Collaborator, $http, confirmMessage) {
  var vm = this;

  vm.new_role = 'reader';

  vm.isDisabledDeleteAllButton = function() {
    var is_selected = true;
    var result = _.select(vm.collaborators, function(c) {
      if (c.check_delete) {
        is_selected = false;
      }
    });
    return is_selected;
  };

  vm.getCollaborators = function(val) {
    if (val.length <= 2) {
      return [];
    }
    return Collaborator.find(vm.name_with_owner, val);
  };

  vm.selectCollaborator = function(item, model, label) {
    vm.selected_new_collaborator = item;
    return false;
  };

  vm.addCollaborator = function($event) {
    $event.preventDefault();
    $event.stopPropagation();

    Collaborator.add(
                     vm.name_with_owner,
                     vm.selected_new_collaborator,
                     vm.new_role,
                     vm.project_id
                    )
      .success(function(data) {
        vm.collaborators.push(data);
        $.notify(data.message, 'success');
      })
      .error(function(data) {
        $.notify(data.message, 'error');
      });

    vm.new_collaborator_uname = null;
    vm.selected_new_collaborator = null;
    return false;
  };

  vm.removeCollaborator = function(member, need_confirm) {
    if (need_confirm === undefined) {
      need_confirm = true;
    }

    if (need_confirm && !confirmMessage.show()) {
      return false;
    }

    Collaborator.remove(vm.name_with_owner, member.id)
      .success(function(data) {
        vm.collaborators = _.reject(vm.collaborators, function(c) {
          return c.id === member.id;
        });
        $.notify(data.message, 'success');
      })
      .error(function(data) {
        $.notify(data.message, 'error');
      });

    return false;
  };

  vm.removeCollaborators = function() {
    if (!confirmMessage.show()) {
      return false;
    }

    _.each(vm.collaborators, function(c) {
      if (c.check_delete) {
        vm.removeCollaborator(c, false);
      }
    });
    return false;
  };

  vm.updateCollaborator = function(member) {
    if (!confirmMessage.show()) {
      return false;
    }

    Collaborator.update(vm.name_with_owner, member)
      .success(function(data) {
        $.notify(data.message, 'success');
      })
      .error(function(data) {
        $.notify(data.message, 'error');
      });
    return false;
  };

  var init = function(dataservice) {
    vm.name_with_owner = dataservice.name_with_owner;
    vm.project_id = dataservice.project_id;
    vm.collaborators = dataservice.collaborators;
  };

  init(dataservice);
  return true;
};

angular
  .module("RosaABF")
  .controller("CollaboratorsController", CollaboratorsController);

CollaboratorsController.$inject = [
  'CollaboratorsInitializer',
  'Collaborator',
  '$http',
  'confirmMessage'
];

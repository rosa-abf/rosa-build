var LabelsController = function(dataservice, $http, Label, $rootScope, $scope, confirmMessage) {

  $scope.$watch(function() {
    return vm.label.color;
  }, function() {
    if (vm.label.color) {
      vm.label.color = vm.label.color.replace(/[^a-f0-9]/gmi, '');
    }
  });

  var vm = this;

  vm.colorClass = function(color) {
    if (vm.label.color == color) {
      return 'fa-check-circle';
    } else {
      return 'fa-circle';
    }
  };

  vm.colorStyle = function(color) {
    return { color: '#' + color };
  };

  vm.colorPreviewStyle = function() {
    return {
      color: '#FFF',
      background: '#' + vm.label.color
    };
  };

  vm.selectCurrentLabel = function(l) {
    vm.label.id = l.id;
    vm.label.name = l.name;
    vm.label.color = l.color;
    vm.is_new_label = false;
    return false;
  };

  vm.saveLabel = function() {
    if (!vm.label.name || !vm.label.color) {
      return false;
    }

    var promise;
    if (vm.is_new_label) {
      promise = Label.add(vm.project, vm.label);
    } else {
      promise = Label.update(vm.project, vm.label);
    }

    promise.success(function(data) {
      vm.labels = data;
      vm.errors = [];
      $rootScope.$broadcast('updateLabels');
    }).error(function(data) {
      vm.errors = data;
    });

    return false;
  };

  vm.removeLabel = function(l) {
    if (!confirmMessage.show()) {
      return false;
    }

    var promise = Label.remove(vm.project, l);
    promise.success(function(data) {
      $rootScope.$broadcast('updateLabels');
    });

    return false;
  };

  var init = function(dataservice) {
    vm.project = dataservice.project;
    vm.labels = dataservice.labels;
    vm.is_collapsed_manage_block = true;

    vm.default_colors = Label.default_colors;
    vm.label = {
      id: null,
      name: null,
      color: vm.default_colors[0]
    };
    vm.is_new_label = true;
    vm.processing = false;
  };

  init(dataservice);
  return true;
};

angular
  .module("RosaABF")
  .controller("LabelsController", LabelsController);

LabelsController.$inject = [
  'LabelsInitializer',
  '$http',
  'Label',
  '$rootScope',
  '$scope',
  'confirmMessage'
];

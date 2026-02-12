var NewMassBuildController = function(dataservice, $http, MassBuild) {

  var vm = this;

  vm.projects_list = '';

  vm.isDisabledRepo = function(repo) {
    var tmp = repo.checked;
    tmp = vm.projects_list.length;
    return repo.checked && vm.projects_list.length > 0;
  };

  vm.selectRepository = function(repo) {
    if (!repo.checked) {
      return false;
    }

    var promise = MassBuild.get_projects(vm.platform_id, repo.id);

    promise.success(function(data) {
      if (data && vm.projects_list.length > 0 && vm.projects_list.slice(-1) !== '\n') {
        vm.projects_list = vm.projects_list + '\n';
      }

      if (data) {
        vm.projects_list = vm.projects_list + data;
      }
    });

    return false;
  };

  vm.changeProjectsList = function() {
    _.each(vm.repositories, function(l) {
      l.checked = false;
    });
    return false;
  };

  vm.selectExtraRepository = function(item, model, label) {
    vm.selected_extra_repository = item;
    return false;
  };

  vm.getExtraRepositories = function(val) {
    var path = Routes.autocomplete_extra_repositories_autocompletes_path({
                                                                         platform_id: vm.platform_id,
                                                                         build_for_platform_id: vm.build_for_platform_id,
                                                                         term: val
    });

    return $http.get(path).then(function(response) {
      return response.data;
    });
  };

  vm.removeExtraRepository = function(id) {
    vm.extra_repositories = _.reject(vm.extra_repositories, function(repo) {
      return repo.id === id;
    });
    return false;
  };

  vm.addExtraRepository = function() {
    vm.extra_repositories = _.union(vm.extra_repositories, [vm.selected_extra_repository]);
    vm.selected_extra_repository = null;
    return false;
  };

  vm.selectExtraBuildList = function(item, model, label) {
    vm.selected_extra_build_list = item;
    return false;
  };

  vm.getExtraBuildLists = function(val) {
    var path = Routes.autocomplete_extra_build_list_autocompletes_path({
                                                                       platform_id: vm.platform_id,
                                                                       term: val
    });

    return $http.get(path).then(function(response) {
      return response.data;
    });
  };

  vm.removeExtraBuildList = function(id) {
    vm.extra_build_lists = _.reject(vm.extra_build_lists, function(repo) {
      return repo.id === id;
    });
    return false;
  };

  vm.addExtraBuildList = function() {
    vm.extra_build_lists = _.union(vm.extra_build_lists, [vm.selected_extra_build_list]);
    vm.selected_extra_build_list = null;
    return false;
  };

  vm.selectExtraMassBuild = function(item, model, label) {
    vm.selected_extra_mass_build = item;
    return false;
  };

  vm.getExtraMassBuilds = function(val) {
    var path = Routes.autocomplete_extra_mass_build_autocompletes_path({
                                                                       platform_id: vm.platform_id,
                                                                       term: val
    });

    return $http.get(path).then(function(response) {
      return response.data;
    });
  };

  vm.removeExtraMassBuild = function(id) {
    vm.extra_mass_builds = _.reject(vm.extra_mass_builds, function(repo) {
      return repo.id === id;
    });
    return false;
  };

  vm.addExtraMassBuild = function() {
    vm.extra_mass_builds = _.union(vm.extra_mass_builds, [vm.selected_extra_mass_build]);
    vm.selected_extra_mass_build = null;
    return false;
  };

  var init = function(dataservice) {
    vm.platform_id = dataservice.platform_id;
    vm.repositories = dataservice.repositories;

    vm.extra_repositories = [];
    vm.extra_build_lists = [];
    vm.extra_mass_builds = [];
  };

  init(dataservice);
  return true;
};

angular
  .module("RosaABF")
  .controller("NewMassBuildController", NewMassBuildController);

NewMassBuildController.$inject = ['newMassBuildInitializer', '$http', 'MassBuild'];

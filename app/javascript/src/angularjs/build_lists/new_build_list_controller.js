var NewBuildListController = function(dataservice, $http) {

  var isBuildForMainPlatform = function() {
    var result = _.select(vm.platforms, function(e) {
      return e.id === vm.build_for_platform_id;
    });
    return result.length === 1;
  };

  var defaultSaveToRepository = function() {
    if (!vm.save_to_repositories) {
      return {};
    }

    var result = _.select(vm.save_to_repositories, function(e) {
      return e.id === vm.save_to_repository_id ||
        (!vm.save_to_repository_id &&
          e.default_branch === vm.project_version_name);
    });

    if (result.length === 0) {
      return vm.save_to_repositories[0];
    }
    return result[0];
  };

  var defaultProjectVersion = function() {
    if (!vm.project_versions) {
      return {};
    }

    var result = _.select(vm.project_versions, function(e) {
      return e.name === vm.default_project_version_name;
    });

    if (result.length === 0) {
      return vm.project_versions[0];
    }
    return result[0];
  };

  var vm = this;

  vm.selectSaveToRepository = function() {
    var setProjectVersion = function() {
      if (!vm.project_versions) {
        return null;
      }

      var result = _.select(vm.project_versions, function(e) {
        return e.name === vm.project_version_name;
      });

      if (result.length === 0) {
        return defaultProjectVersion();
      }
      return result[0];
    };

    var changeStatusRepositories = function() {
      if (!vm.platforms) {
        return;
      }

      _.each(vm.platforms, function(pl) {
        _.each(pl.repositories, function(r) {
          if (pl.id !== vm.build_for_platform_id) {
            r.checked = false;
          }
          if (pl.id === vm.build_for_platform_id ||
              (!vm.is_build_for_main_platform &&
                vm.project_version &&
                vm.project_version.name === pl.name)) {

            if (r.name === 'main' || r.name === 'base' || r.name === vm.save_to_repository.repo_name) {
              r.checked = true;
            }
          }
        });
      });
    };

    var updateDefaultArches = function() {
      if (!vm.arches) {
        return;
      }

      _.each(vm.arches, function(a) {
        a.checked = _.contains(vm.save_to_repository.default_arches, a.id);
      });
    };

    var getExtraRepos = function() {
      if (!vm.default_extra_repos || vm.is_build_for_main_platform) {
        return null;
      }

      var result = _.select(vm.default_extra_repos, function(e) {
        return e.platform_id === vm.build_for_platform_id;
      });

      return result;
    };

    var setAutoCreateContainerAndAutoPublish = function() {
      if (!vm.is_build_for_main_platform) {
        vm.auto_create_container = false;
      }

      if (vm.save_to_repository.publish_without_qa) {
        vm.auto_publish_status = 'default';
      } else {
        vm.auto_publish_status = 'none';
        vm.auto_create_container = true;
      }
    };

    vm.build_for_platform_id = vm.save_to_repository.platform_id;
    vm.is_build_for_main_platform = isBuildForMainPlatform();

    vm.project_version_name = vm.save_to_repository.default_branch;

    if (vm.is_build_for_main_platform) {
      vm.project_version = setProjectVersion();
    }

    changeStatusRepositories();
    updateDefaultArches();
    vm.extra_repositories = getExtraRepos();
    setAutoCreateContainerAndAutoPublish();

    return true;
  };

  vm.selectProjectVersion = function() {
    if (!vm.project_versions) {
      return;
    }

    if (!vm.is_build_for_main_platform) {
      vm.selectSaveToRepository();
    }
  };

  vm.selectExtraRepository = function(item, model, label) {
    vm.selected_extra_repository = item;
    return false;
  };

  vm.getExtraRepositories = function(val) {
    var path = Routes.autocomplete_extra_repositories_autocompletes_path({
       platform_id: vm.build_for_platform_id,
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
      platform_id: vm.build_for_platform_id,
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
    if (vm.selected_extra_build_list && vm.selected_extra_build_list.id) {
      vm.extra_build_lists = _.union(vm.extra_build_lists, [vm.selected_extra_build_list]);
    }
    vm.selected_extra_build_list = null;
    return false;
  };

  vm.updateFilterOwner = function() {
    vm.last_build_lists_filter.owner = !vm.last_build_lists_filter.owner;
    updateLastBuilds();
  };

  vm.updateFilterStatus = function() {
    vm.last_build_lists_filter.status = !vm.last_build_lists_filter.status;
    updateLastBuilds();
  };

  var updateLastBuilds = function() {
    var path = Routes.list_project_build_lists_path({
      name_with_owner: vm.name_with_owner,
      page: vm.last_build_lists_filter.page,
      owner_filter: vm.last_build_lists_filter.owner,
      status_filter: vm.last_build_lists_filter.status
    });

    $http.get(path).then(function(response) {
      vm.last_build_lists = response.data.build_lists;
      vm.total_items = response.data.total_items;
    });

    return false;
  };

  vm.goToPage = function(page) {
    vm.last_build_lists_filter.page = page;
    updateLastBuilds();
  };

  vm.cloneBuildList = function(id) {
    var path = Routes.new_project_build_list_path({
      name_with_owner: vm.name_with_owner,
      build_list_id: id,
      show: 'inline'
    });

    $http.get(path).then(function(response) {
      init(response.data);
      return true;
    });
  };

  var init = function(dataservice) {
    vm.name_with_owner = dataservice.name_with_owner;
    vm.platforms = dataservice.platforms;
    vm.save_to_repositories = dataservice.save_to_repositories;
    vm.project_versions = dataservice.project_versions;

    vm.auto_publish_status = dataservice.auto_publish_status;
    vm.auto_create_container = dataservice.auto_create_container;

    vm.default_project_version_name = dataservice.project_version;
    vm.project_version_name = dataservice.project_version;
    vm.project_version = defaultProjectVersion();
    vm.save_to_repository_id = dataservice.save_to_repository_id;
    vm.save_to_repository = defaultSaveToRepository();

    if (vm.save_to_repository) {
      vm.build_for_platform_id = vm.save_to_repository.platform_id;
    }

    vm.default_extra_repos = dataservice.default_extra_repos;
    vm.extra_repositories = dataservice.extra_repos;
    vm.extra_build_lists = dataservice.extra_build_lists;

    vm.arches = dataservice.arches;

    vm.is_build_for_main_platform = isBuildForMainPlatform();
    vm.hidePlatform = function(platform) {
      return vm.is_build_for_main_platform && platform.id !== vm.build_for_platform_id;
    };

    if (!vm.last_build_lists) {
      vm.last_build_lists = [];
      vm.last_build_lists_filter = { owner: true, status: true, page: 1 };
      updateLastBuilds();
    }
  };

  init(dataservice);

  if (!dataservice.build_list_id) {
    vm.selectSaveToRepository();
  }

  return true;
};

angular
  .module("RosaABF")
  .controller("NewBuildListController", NewBuildListController);

NewBuildListController.$inject = ['newBuildInitializer', '$http'];

NewBuildListController = (dataservice, $http) ->

  isBuildForMainPlatform = ->
    result = _.select(vm.platforms, (e) ->
      e.id is vm.build_for_platform_id
    )
    result.length is 1

  defaultSaveToRepository = ->
    return {} unless vm.save_to_repositories

    result = _.select(vm.save_to_repositories, (e) ->
      e.id is vm.save_to_repository_id or
      !vm.save_to_repository_id and
      e.platform_name is vm.project_version_name
    )
    return vm.save_to_repositories[0] if result.length is 0
    result[0]

  defaultProjectVersion = ->
    return {} unless vm.project_versions

    result = _.select(vm.project_versions, (e) ->
      e.name is vm.default_project_version_name
    )
    return vm.project_versions[0] if result.length is 0
    result[0]


  vm = this

  vm.selectSaveToRepository = ->
    setProjectVersion = ->
      return null unless vm.project_versions

      result = _.select(vm.project_versions, (e) ->
        e.name is vm.project_version_name
      )
      return defaultProjectVersion() if result.length is 0
      result[0]

    changeStatusRepositories = ->
      return unless vm.platforms
      _.each(vm.platforms, (pl) ->
        _.each(pl.repositories, (r) ->
          if pl.id isnt vm.build_for_platform_id
            r.checked = false
          if pl.id is vm.build_for_platform_id or
             (!vm.is_build_for_main_platform and
              vm.project_version and
              vm.project_version.name is pl.name)
            r.checked = true if r.name is 'main' or r.name is 'base' or r.name is vm.save_to_repository.repo_name
        )
      )

    updateDefaultArches = ->
      return unless vm.arches
      _.each(vm.arches, (a) ->
        a.checked = _.contains(vm.save_to_repository.default_arches, a.id)
      )

    getExtraRepos = ->
      return null if !vm.default_extra_repos || vm.is_build_for_main_platform

      result = _.select(vm.default_extra_repos, (e) ->
        e.platform_id is vm.build_for_platform_id
      )
      return result

    setAutoCreateContainerAndAutoPublish = ->
      vm.auto_create_container = false if !vm.is_build_for_main_platform
      if vm.save_to_repository.publish_without_qa
        vm.auto_publish_status = 'default'
      else
        vm.auto_publish_status   = 'none'
        vm.auto_create_container = true

    vm.build_for_platform_id = vm.save_to_repository.platform_id
    vm.is_build_for_main_platform = isBuildForMainPlatform()

    vm.project_version_name = vm.save_to_repository.platform_name
    vm.project_version = setProjectVersion() if vm.is_build_for_main_platform

    changeStatusRepositories()
    updateDefaultArches()
    vm.extra_repositories = getExtraRepos()
    setAutoCreateContainerAndAutoPublish()
    true

  vm.selectProjectVersion = ->
    return unless vm.project_versions
    vm.selectSaveToRepository() unless vm.is_build_for_main_platform

  vm.selectExtraRepository = (item, model, label) ->
    vm.selected_extra_repository = item
    false

  vm.getExtraRepositories = (val) ->
    path = Routes.autocomplete_extra_repositories_autocompletes_path(
      {
        platform_id: vm.build_for_platform_id,
        term:        val
      }
    )

    return $http.get(path).then (response) ->
      response.data

  vm.removeExtraRepository = (id) ->
    vm.extra_repositories = _.reject(vm.extra_repositories, (repo) ->
      return repo.id is id
    )
    false

  vm.addExtraRepository = ->
    vm.extra_repositories = _.union(vm.extra_repositories, [vm.selected_extra_repository])
    vm.selected_extra_repository = null
    false

  vm.selectExtraBuildList = (item, model, label) ->
    vm.selected_extra_build_list = item
    false

  vm.getExtraBuildLists = (val) ->
    path = Routes.autocomplete_extra_build_list_autocompletes_path(
      {
        platform_id: vm.build_for_platform_id,
        term:        val
      }
    )

    return $http.get(path).then (response) ->
      response.data

  vm.removeExtraBuildList = (id) ->
    vm.extra_build_lists = _.reject(vm.extra_build_lists, (repo) ->
      return repo.id is id
    )
    false

  vm.addExtraBuildList = ->
    if vm.selected_extra_build_list && vm.selected_extra_build_list.id
      vm.extra_build_lists = _.union(vm.extra_build_lists, [vm.selected_extra_build_list])
    vm.selected_extra_build_list = null
    false

  vm.updateFilterOwner = ->
    vm.last_build_lists_filter.owner = !vm.last_build_lists_filter.owner;
    updateLastBuilds()

  vm.updateFilterStatus = ->
    vm.last_build_lists_filter.status = !vm.last_build_lists_filter.status;
    updateLastBuilds()

  updateLastBuilds = ->
    path = Routes.list_project_build_lists_path(
      {
        name_with_owner: vm.name_with_owner,
        page:            vm.last_build_lists_filter.page
        owner_filter:    vm.last_build_lists_filter.owner
        status_filter:   vm.last_build_lists_filter.status
      }
    )

    $http.get(path).then (response) ->
      vm.last_build_lists = response.data.build_lists
      vm.total_items      = response.data.total_items
    false

  vm.goToPage = (page) ->
    vm.last_build_lists_filter.page = page
    updateLastBuilds()

  vm.cloneBuildList = (id) ->
    path = Routes.new_project_build_list_path(
      {
        name_with_owner: vm.name_with_owner,
        build_list_id:   id,
        show:            'inline'
      }
    )

    $http.get(path).then (response) ->
      init(response.data)
      true


  init = (dataservice) ->

    vm.name_with_owner              = dataservice.name_with_owner
    vm.platforms                    = dataservice.platforms
    vm.save_to_repositories         = dataservice.save_to_repositories
    vm.project_versions             = dataservice.project_versions

    vm.auto_publish_status          = dataservice.auto_publish_status
    vm.auto_create_container        = dataservice.auto_create_container

    vm.default_project_version_name = dataservice.project_version
    vm.project_version_name         = dataservice.project_version
    vm.project_version              = defaultProjectVersion()
    vm.save_to_repository_id        = dataservice.save_to_repository_id
    vm.save_to_repository           = defaultSaveToRepository()
    if vm.save_to_repository
      vm.build_for_platform_id      = vm.save_to_repository.platform_id

    vm.default_extra_repos          = dataservice.default_extra_repos
    vm.extra_repositories           = dataservice.extra_repos
    vm.extra_build_lists            = dataservice.extra_build_lists

    vm.arches                       = dataservice.arches

    vm.is_build_for_main_platform   = isBuildForMainPlatform()
    vm.hidePlatform                 = (platform) ->
      vm.is_build_for_main_platform and platform.id isnt vm.build_for_platform_id

    if !vm.last_build_lists
      vm.last_build_lists           = []
      vm.last_build_lists_filter    = { owner: true, status: true, page: 1 }
      updateLastBuilds()

  init(dataservice)
  vm.selectSaveToRepository() if !dataservice.build_list_id
  return true

angular
  .module("RosaABF")
  .controller "NewBuildListController", NewBuildListController

NewBuildListController.$inject = ['newBuildInitializer', '$http']

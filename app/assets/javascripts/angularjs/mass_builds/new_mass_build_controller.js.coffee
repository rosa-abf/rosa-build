NewMassBuildController = (dataservice, $http, MassBuild) ->

  vm = this

  vm.projects_list = ''

  vm.isDisabledRepo = (repo) ->
    tmp = repo.checked
    tmp = vm.projects_list.length
    repo.checked and vm.projects_list.length > 0

  vm.selectRepository = (repo) ->
    return false unless repo.checked

    promise = MassBuild.get_projects(vm.platform_id, repo.id)

    promise.success (data) ->
      if data and vm.projects_list.length > 0 and vm.projects_list.slice(-1) is not '\n'
        vm.projects_list = vm.projects_list + '\n'

      vm.projects_list = vm.projects_list + data if data

    false

  vm.changeProjectsList = ->
    _.each(vm.repositories, (l) ->
      l.checked = false
    )
    false

  vm.selectExtraRepository = (item, model, label) ->
    vm.selected_extra_repository = item
    false

  vm.getExtraRepositories = (val) ->
    path = Routes.autocomplete_extra_repositories_autocompletes_path(
      {
        platform_id:           vm.platform_id,
        build_for_platform_id: vm.build_for_platform_id,
        term:                  val
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
        platform_id: vm.platform_id,
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
    vm.extra_build_lists = _.union(vm.extra_build_lists, [vm.selected_extra_build_list])
    vm.selected_extra_build_list = null
    false

  vm.selectExtraMassBuild = (item, model, label) ->
    vm.selected_extra_mass_build = item
    false

  vm.getExtraMassBuilds = (val) ->
    path = Routes.autocomplete_extra_mass_build_autocompletes_path(
      {
        platform_id: vm.platform_id,
        term:        val
      }
    )

    return $http.get(path).then (response) ->
      response.data

  vm.removeExtraMassBuild = (id) ->
    vm.extra_mass_builds = _.reject(vm.extra_mass_builds, (repo) ->
      return repo.id is id
    )
    false

  vm.addExtraMassBuild = ->
    vm.extra_mass_builds = _.union(vm.extra_mass_builds, [vm.selected_extra_mass_build])
    vm.selected_extra_mass_build = null
    false

  init = (dataservice) ->

    vm.platform_id  = dataservice.platform_id
    vm.repositories = dataservice.repositories

    vm.extra_repositories     = []
    vm.extra_build_lists      = []
    vm.extra_mass_build_lists = []


  init(dataservice)
  return true

angular
  .module("RosaABF")
  .controller "NewMassBuildController", NewMassBuildController

NewMassBuildController.$inject = ['newMassBuildInitializer', '$http', 'MassBuild']

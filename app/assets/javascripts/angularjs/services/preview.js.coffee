previewService = ($http) ->
  old_text = ''
  {
    old_text: old_text
    get_preview: (name_with_owner, text, old_text) ->
      return null if text is old_text
      path = Routes.project_md_preview_path(name_with_owner)
      $http.post(path, {text: text})
  }

angular
  .module("RosaABF")
  .factory "Preview", previewService

previewService.$inject = ['$http']

var previewService = function($http) {
  var old_text = '';

  return {
    old_text: old_text,
    get_preview: function(name_with_owner, text, old_text_param) {
      if (text === old_text_param) {
        return null;
      }
      var path = Routes.project_md_preview_path(name_with_owner);
      return $http.post(path, { text: text });
    }
  };
};

angular
  .module("RosaABF")
  .factory("Preview", previewService);

previewService.$inject = ['$http'];

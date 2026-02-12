var compileHTML = function($compile) {
  return {
    run: function(scope, data) {
      var template = angular.element(data);
      var linkFn = $compile(template);
      return linkFn(scope);
    }
  };
};

angular
  .module("RosaABF")
  .service("compileHTML", compileHTML);

compileHTML.$inject = ['$compile'];

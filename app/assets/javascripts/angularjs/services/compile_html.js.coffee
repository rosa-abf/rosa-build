compileHTML = ($compile) ->
  run: (scope, data) ->
    template = angular.element(data)
    linkFn   = $compile(template)
    linkFn(scope)

angular
  .module("RosaABF")
  .service "compileHTML", compileHTML

compileHTML.$inject = ['$compile']

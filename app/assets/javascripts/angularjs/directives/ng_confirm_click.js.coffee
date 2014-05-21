RosaABF = angular.module 'RosaABF'

RosaABF.directive "ngConfirmClick", ->
  priority: 100
  restrict: "A"
  link: (scope, element, attr) ->
    msg = attr.ngConfirmClick || "Are you sure?"
    element.bind 'click', (event) ->
      unless confirm(msg)
        event.stopImmediatePropagation()
        event.preventDefault

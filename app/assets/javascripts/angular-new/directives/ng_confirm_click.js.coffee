RosaABF = angular.module 'RosaABF'

RosaABF.directive "ngConfirmClick", ->
  priority: 100
  restrict: "A"
  link: (scope, element, attr) ->
    msg = attr.ngConfirmClick || "Are you sure?"
    clickAction = attr.confirmedClick
    element.bind 'click', (event) ->
      if clickAction
        scope.$apply clickAction if window.confirm(msg)
      else
        unless confirm(msg)
          event.stopImmediatePropagation()
          event.preventDefault

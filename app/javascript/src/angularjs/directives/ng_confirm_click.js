RosaABF = angular.module('RosaABF');

RosaABF.directive("ngConfirmClick", function() {
  return {
    priority: 100,
    restrict: "A",
    link: function(scope, element, attr) {
      var msg = attr.ngConfirmClick || "Are you sure?";
      var clickAction = attr.confirmedClick;

      element.bind('click', function(event) {
        if (clickAction) {
          if (window.confirm(msg)) {
            scope.$apply(clickAction);
          }
        } else {
          if (!confirm(msg)) {
            event.stopImmediatePropagation();
            event.preventDefault();
          }
        }
      });
    }
  }
});


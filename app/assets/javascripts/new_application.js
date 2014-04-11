//= require jquery
//= require jquery_ujs
//= require js-routes

// Loads all Bootstrap javascripts
//= require bootstrap

// require unstable/angular
//= require angular
//= require angular-sanitize
//= require angular-ui-bootstrap-tpls
//= require ui-codemirror
//= require angular-i18n
//= require angularjs/locales

//= require moment
//= require angularjs/angular-moment

//= require_tree ./angular-new
//= require loading-bar

//= require codemirror
// ### TODO require all files in codemirror/modes ###
//= require codemirror/modes/ruby
//= require codemirror/modes/javascript
//= require codemirror/modes/markdown

$(document).ready(function() {
  window.CodeMirrorRun = function(code) {
    //CodeMirror.runMode(code.innerHTML.replace(/&amp;/gi, '&').replace(/&lt;/gi, '<').replace(/&gt;/gi, '>'), code.className, code);
    CodeMirror.runMode(code.innerHTML, 'markdown', code);
  }

  $('.md_and_cm').each(function (code) { CodeMirrorRun(this); });

});

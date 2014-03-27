//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require jquery-migrate-min
//= require pirobox_extended_min
//= require ./design/all

$(document).ready(function() {
  $('div.information > div.profile > a').on('click', function(e) {
      e.preventDefault();
  });
});
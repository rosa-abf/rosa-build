$(document).ready(function() {
  $('#pull_tabs a').on('click', function (e) {
    var href = $(this).attr("href");

    if ( window.history && history.pushState ) {
      history.pushState("", "", href);
      history.replaceState("", "", href);
    } else {
      location.hash = href;
    }
  });

  var diff_tab = $('#pull_tabs a[href="#diff"]');
  $('.link_to_full_changes').on('click', function(){
    diff_tab.tab('show');
  });
});

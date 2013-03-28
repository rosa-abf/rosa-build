$(document).ready(function() {

  jQuery(window).bind('hashchange', function(e) {
    var hash = location.hash;
    if (/^#(diff|discussion)-F[0-9]+(L|R)[0-9]+/.test(hash)) {
      highlightDiff(hash);
    } else if (/^#L[0-9]+/.test(hash)) {
      highlightShow(hash);
    }
  });

  // Since the event is only triggered when the hash changes, we need to trigger
  // the event now, to handle the hash the page may have loaded with.
  jQuery(window).trigger('hashchange');

});


function highlightShow(id) {
  $('.highlight-line').remove();
  $(id).append('<div class="highlight-line"></div>');
}

function highlightDiff(id) {
  $('.highlight-line').removeClass('highlight-line');
  $(id).parent().find('td.code').addClass('highlight-line');
}
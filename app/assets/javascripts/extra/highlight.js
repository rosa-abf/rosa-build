$(document).ready(function() {

  jQuery(window).bind('hashchange', function(e) {
    var hash = location.hash;
    if (/^#diff-/.test(hash)) {
      highlightDiff(hash);
    } else if (/^#L[0-9]+/.test(hash)) {
      highlightShow(hash);
    }
  });

  $(window).load(function() {
    // this code will run after all other $(document).ready() scripts
    // have completely finished, AND all page elements are fully loaded.
    jQuery(window).trigger('hashchange');
  });

});


function highlightShow(id) {
  $('.highlight-line').remove();
  $(id).append('<div class="highlight-line"></div>');
}

function highlightDiff(id) {
  $('.highlight-line').removeClass('highlight-line');
  $(id).parent().find('td.code').addClass('highlight-line');
}
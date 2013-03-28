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
  var from = to = id.substring(2);
  if (/[0-9]+\-L[0-9]+$/.test(from)) {
    var index = to.indexOf('-');
    to    = to.substring(index + 2);
    from  = from.substring(0, index);
  }
  from  = parseInt(from);
  to    = parseInt(to);
  if (from && to) {
    if (from > to) {
      var x = to; to = from; from = x;
    }
    var el = $('#L' + from);
    $(document).scrollTop( el.offset().top );
    while (el.length > 0) {
      el.append('<div class="highlight-line"></div>');
      if (from == to) { return true; }
      from += 1;
      el = $('#L' + from);
    }
  }
}

function highlightDiff(id) {
  $('.highlight-line').removeClass('highlight-line');
  $(id).parent().find('td.code').addClass('highlight-line');
}
// Disable checkboxes selection for history table for more than 2 versions:
//$(document).ready(function() {
  if ('.wiki .history') {
    $('.niceCheck-main').click(function() {
      var count = 0;
      $('input.history_cbx').each(function(i,el) {
        if ($(el).attr('checked')) {
          count = count + 1;
        }
      });
      if (count > 2) {
        var cbx = $( $(this).find('input.history_cbx')[0] );
        if ( cbx.attr('checked') ) {
          $(this).css('background-position', '0pt 0px');
          cbx.removeAttr('checked');
        }
      }
    });
  }
//});

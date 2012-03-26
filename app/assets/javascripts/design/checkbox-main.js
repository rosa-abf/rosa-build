function changeCheck(el) {
  var el = el, input = el.find('input[type="checkbox"]');

  if(input.attr("checked")) {
    el.css('backgroundPosition', '0 0');
    input.removeAttr('checked');
  } else {
    el.css('backgroundPosition', '0 -18px');
    input.attr('checked', true);
  }

  return true;
}

function startChangeCheck(el) {
  var el = el, input = el.find('input[type="checkbox"]');

  if(input.attr('checked')) {
    el.css('backgroundPosition', '0 -18px');
  }

  return true;
}

$(document).ready(function(){
  $('.niceCheck-main').each(function(i,el) {
    startChangeCheck($(el));
  });
  $('.niceCheck-main').click(function() {
    changeCheck($(this));
  });
});

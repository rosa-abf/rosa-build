// http://sitear.ru/material/sozdaem-knopku-naverh-scroll-to-top-na-jquery
$(document).ready(function() {
  $(window).scroll(function() {
    if ($(this).scrollTop() > 0) {
      $("#scroller").fadeIn();
    } else {
      $("#scroller").fadeOut();
    }
    return;
  });

  $("#scroller").click(function() {
    $("body, html").animate({
                            scrollTop: 0
    }, 400);
    return false;
  });

  return;
});

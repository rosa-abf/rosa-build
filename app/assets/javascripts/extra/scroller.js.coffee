# http://sitear.ru/material/sozdaem-knopku-naverh-scroll-to-top-na-jquery
$(window).scroll ->
  if $(this).scrollTop() > 0
    $("#scroller").fadeIn()
  else
    $("#scroller").fadeOut()
  return

$("#scroller").click ->
  $("body,html").animate
    scrollTop: 0
  , 400
  false

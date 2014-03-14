$(document).ready(function() {

  $(".div-filter-labels").on('click', function() {
    var flag = this.id;
    flag = flag.replace("label-","flag-");
    var bg = $("#"+flag).css("background-color");
    var checkbox = $(this).find(':checkbox');
    if ($(this).css("background-color") != bg) {
      $(this).css("background-color",bg).css("color","#FFFFFF");
      checkbox.attr('checked', 'checked');
    } else {
      $(this).css("background-color","rgb(247, 247, 247)").css("color","#565657");
      checkbox.removeAttr('checked');
    }
  });

});

$(document).ready(function() {

  $(".div-filter-labels").live('click', function() {
    var flag = this.id;
    flag = flag.replace("label-","flag-");
    var bg = $("#"+flag).css("background-color");
    var checkbox = $(this).find(':checkbox');
    if ($(this).css("background-color") != bg) {
      $(this).css("background-color",bg);
      $(this).css("color","#FFFFFF");
      checkbox.attr('checked', 'checked');
    } else {
      $(this).css("background-color","rgb(247, 247, 247)");
      $(this).css("color","#565657");
      checkbox.removeAttr('checked');
    }
  });

});

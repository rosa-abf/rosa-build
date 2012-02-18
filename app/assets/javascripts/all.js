
var droplist = function() {
    $user_menu.slideToggle("slow");
}

function loadMessages() {
	$("#messages-new").fadeOut("slow");
	$("#new-messages").delay(700).fadeIn("slow");
}
function loadOldMessages() {
	$("#old-messages").fadeIn("slow");
}

$(document).ready(function(){
    $user_menu = $('#droplist');
    $user_menu.die('click');

    $('div.information > div.user').live('click', function() {
        if ($user_menu.is(":hidden")) {
            droplist();
        }
    });

    $('div.information > div.profile > a').live('click', function(e) {
        e.preventDefault();
    });
    
    $('.data-expander').live('click', function(e) {
      var $button = $(e.target);
      var id = "#content-" + $button.attr('id');
      var $slider = $(id);
      $slider.slideToggle("slow", function(){
        $button.toggleClass('expanded collapsed');
      });
    });
});
 
$(document).click(function(e) {
    if (!$user_menu.is(":hidden") && ($(e.target).parent().attr('id') != $user_menu.attr('id'))) {
        droplist();
    }
});

function showActivity(elem) {
	$("#activity-bottom"+elem).slideToggle("slow");
	var img = $("#expand" + elem).attr("src");
	if (img == "/assets/expand-gray.png") {
		$("#expand" + elem).attr("src","/assets/expand-gray2.png");
	} else {
		$("#expand" + elem).attr("src","/assets/expand-gray.png");
	}
}

var state = 0;

function droplist() {
	if (state == 0) {
		$("#droplist").slideToggle("slow");
		//borderDown();
		state = 1;
	}
}

function loadMessages() {
	$("#messages-new").fadeOut("slow");
	$("#new-messages").delay(700).fadeIn("slow");
	//setTimeout(border1, 700)
}
function loadOldMessages() {
	$("#old-messages").fadeIn("slow");
	//setTimeout(border1, 700)
}

 
$(document).click(function() {
	var dl = $("#droplist").css("height");
	var dl2 = $("#droplist").css("display");
	if ((dl2 == "block")&&(dl == "91px")) {
		state = 0;
		droplist();
		state = 0;
	}
});

function showActivity(elem) {
	//borderDown();
	$("#activity-bottom"+elem).slideToggle("slow");
	var img = $("#expand" + elem).attr("src");
	if (img == "design/expand-gray.png") {
		$("#expand" + elem).attr("src","design/expand-gray2.png");
	} else {
		$("#expand" + elem).attr("src","design/expand-gray.png");
	}
	//setTimeout(border1, 700)
}
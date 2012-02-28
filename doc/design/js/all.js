var state = 0;

function droplist() {
	if (state == 0) {
		$("#droplist").slideToggle("slow");
		state = 1;
	}
}

function loadMessages() {
	$("#messages-new").fadeOut("slow");
	$("#new-messages").delay(700).fadeIn("slow");
}
function loadOldMessages() {
	$("#old-messages").fadeIn("slow");
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
	$("#activity-bottom"+elem).slideToggle("slow");
	var img = document.getElementById("expand" + elem).className;
	if (img == "expand-gray-down") {
		document.getElementById("expand" + elem).className = "expand-gray-up";
	} else {
		document.getElementById("expand" + elem).className = "expand-gray-down";
	}
}
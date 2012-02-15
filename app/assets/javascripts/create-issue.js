function addPeople(num) {
	$("#people"+num).fadeOut(0);
	$("#people-sections"+num).fadeIn("slow");
	$("#people-sections-list"+num).fadeIn("slow");
	if ($("#people-span").css("display") != "none") {
		$("#people-span").fadeOut(0);
	}
}

function remPeople(num) {
	$("#people"+num).fadeIn("slow");
	$("#people-sections"+num).fadeOut(0);
	$("#people-sections-list"+num).fadeOut(0);
	if (($("#people-sections-list1").css("display") == "none") && ($("#people-sections-list2").css("display") == "none") && ($("#people-sections-list3").css("display") == "none") && ($("#people-sections-list4").css("display") == "none")) {
		$("#people-span").fadeIn("slow");
	}
}

function addFlag(num) {
	$("#flag"+num).fadeOut(0);
	$("#flag-list"+num).fadeIn("slow");
	$("#flag-list-sections"+num).fadeIn("slow");
	if ($("#flag-span").css("display") != "none") {
		$("#flag-span").fadeOut(0);
	}
}

function remFlag(num) {
	$("#flag"+num).fadeIn("slow");
	$("#flag-list"+num).fadeOut(0);
	$("#flag-list-sections"+num).fadeOut(0);
	if (($("#flag-list-sections1").css("display") == "none") && ($("#flag-list-sections2").css("display") == "none") && ($("#flag-list-sections3").css("display") == "none") && ($("#flag-list-sections4").css("display") == "none")) {
		$("#flag-span").fadeIn("slow");
	}
}

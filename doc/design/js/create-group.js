$(document).ready(function() { 
	$("#catchError").click(function() {
		$("#error-warp").slideToggle("slow");
		var inp = document.getElementById("name");
		if (inp.className != "error") {
			inp.className = "error";
		} else {
			inp.className = "";
		}
	});
});
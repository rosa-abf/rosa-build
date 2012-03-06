function logIn() {
	$("#hintLogin").fadeIn("slow");
	document.getElementById("login").className="registartion-input-error";
	$("#hintName").fadeIn("slow");
	document.getElementById("name").className="registartion-input-error";
	$("#hintEmail").fadeIn("slow");
	document.getElementById("email").className="registartion-input-error";
	$("#hintPassword").fadeIn("slow");
	document.getElementById("pass").className="registartion-input-error";
	document.getElementById("pass2").className="registartion-input-error";
}

function disError(elem) {
	$("#hintLogin").fadeOut("fast");
	$("#hintName").fadeOut("fast");
	$("#hintEmail").fadeOut("fast");
	$("#hintPassword").fadeOut("fast");
	if (document.getElementById("login").className=="registartion-input-error") {
		if (this.id=="login") {
			document.getElementById("login").className="registartion-input-focus";
		} else {
			document.getElementById("login").className="registartion-input-no-focus";
		}
	}
	if (document.getElementById("name").className=="registartion-input-error") {
		if (this.id=="name") {
			document.getElementById("name").className="registartion-input-focus";
		} else {
			document.getElementById("name").className="registartion-input-no-focus";
		}
	}
	if (document.getElementById("email").className=="registartion-input-error") {
		if (this.id=="email") {
			document.getElementById("email").className="registartion-input-focus";
		} else {
			document.getElementById("email").className="registartion-input-no-focus";
		}
	}
	if (document.getElementById("pass").className=="registartion-input-error") {
		if (this.id=="pass") {
			document.getElementById("pass").className="registartion-input-focus";
		} else {
			document.getElementById("pass").className="registartion-input-no-focus";
		}
	}
	if (document.getElementById("pass2").className=="registartion-input-error") {
		if (this.id=="pass2") {
			document.getElementById("pass2").className="registartion-input-focus";
		} else {
			document.getElementById("pass2").className="registartion-input-no-focus";
		}
	}
	buttonCheck();
}

/*function disError(elem) {
			buttonCheck();
		}*/
		
function buttonCheck() {
	if ((document.getElementById("login").value!="")&&(document.getElementById("name").value!="")&&(document.getElementById("pass").value!="")&&(document.getElementById("pass2").value!="")&&(document.getElementById("email").value!="")) {
		document.getElementById("btnLogin").className = "button";
	} else {
		document.getElementById("btnLogin").className = "button disabled";
	}
}

$(document).ready(function() {
	$("#btnLogin").click(function() {
		logIn();
	});
});
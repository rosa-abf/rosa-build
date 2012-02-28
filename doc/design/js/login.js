function logIn() {
	$("#hint").fadeIn("slow");
	document.getElementById("login").className="registartion-input-error";
	document.getElementById("pass").className="registartion-input-error";
}

function disError(elem) {
	$("#hint").fadeOut("fast");
	if (document.getElementById("login").className=="registartion-input-error") {
		if (this.id=="login") {
			document.getElementById("login").className="registartion-input-focus";
		} else {
			document.getElementById("login").className="registartion-input-no-focus";
		}
	}
	if (document.getElementById("pass").className=="registartion-input-error") {
		if (this.id=="pass") {
			document.getElementById("pass").className="registartion-input-focus";
		} else {
			document.getElementById("pass").className="registartion-input-no-focus";
		}
	}
	buttonCheck();
}

function buttonCheck() {
	if ((document.getElementById("login").value!="")&&(document.getElementById("login").value!="Логин или email")&&(document.getElementById("pass").value!="")&&(document.getElementById("pass").value!="Пароль")) {
		document.getElementById("btnLogin").className = "button";

	} else {
		document.getElementById("btnLogin").className = "button disabled";
	}
}
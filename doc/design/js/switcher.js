function switchThis() {
	var doc = document.getElementById("switcher");
	if (doc.className == "switcher") {
		doc.className = "switcher-off";
		$("#open-comment").fadeOut(0);
		$("#closed-comment").fadeIn("slow");
	} else {
		doc.className = "switcher";
		$("#closed-comment").fadeOut(0);
		$("#open-comment").fadeIn("slow");
	}
}

function preload() {
  if (document.images) {
	var imgsrc = preload.arguments;
	arr=new Array(imgsrc.length);
	
	for (var j=0; j<imgsrc.length; j++) {
	  arr[j] = new Image;
	  arr[j].src = imgsrc[j];
	}
  }
}

function manage(elem) {
	if (elem == "people") {
		var doc = document.getElementById("people-manage");
		if (doc.className == "view") {
			doc.className = "non-view";
			$("#people-manage").fadeOut(0);
			$("#people-manage-list").fadeIn("slow");
		}
		else {
			$("#people-manage-list").fadeOut(0);
			$("#people-manage").fadeIn("slow");	
			doc.className = "view";					
		}
	}
	if (elem == "labels") {
		var doc = document.getElementById("labels-manage");
		if (doc.className == "view") {
			doc.className = "non-view";
			$("#labels-manage").fadeOut(0);
			$("#labels-manage-list").fadeIn("slow");
		}
		else {
			$("#labels-manage-list").fadeOut(0);
			$("#labels-manage").fadeIn("slow");	
			doc.className = "view";					
		}
	}
	
}
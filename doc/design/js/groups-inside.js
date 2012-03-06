function deleteAdminMember() {
	if (document.getElementById("niceCheckbox1-1").checked == true) {
		$("#admin-table-members-row1").fadeOut("slow");
	}
	if (document.getElementById("niceCheckbox2-1").checked == true) {
		$("#admin-table-members-row2").fadeOut("slow");
	}
	if (document.getElementById("niceCheckbox3-1").checked == true) {
		$("#admin-table-members-row3").fadeOut("slow");
	}
	if (document.getElementById("niceCheckbox4-1").checked == true) {
		$("#admin-table-members-row4").fadeOut("slow");
	}
}
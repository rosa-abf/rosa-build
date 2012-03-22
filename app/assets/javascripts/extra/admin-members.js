/*function deleteAdminMember() {
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
}*/

function saveAdminMember() {
  $('#_method').attr('value', 'post');
  $('form#members_form').submit();
}

function deleteAdminMember() {
  $('#_method').attr('value', 'delete');
  var delete_url = $('form#members_form').attr('delete_url');
  $('form#members_form').attr('action', delete_url);
  $('form#members_form').submit();
}

function saveAdminGroup() {
  $('#groups_method').attr('value', 'post');
  $('form#groups_form').submit();
}

function deleteAdminGroup() {
  $('#groups_method').attr('value', 'delete');
  var delete_url = $('form#groups_form').attr('delete_url');
  $('form#groups_form').attr('action', delete_url);
  $('form#groups_form').submit();
}

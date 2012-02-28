/*$(document).ready(function() { 
$("#myTable").tablesorter({ 
	headers: { 
		2: { 
			sorter: false 
		}
	}

}); 
});
*/
$(document).ready(function() {
  $("a.files-see").click(function() {
	$("#file1").fadeOut(0);
	$("#file2").fadeIn("slow");
	$("#file-name1").fadeOut(0);
	$("#file-name2").fadeIn("slow");
	$("#fork-and-edit").fadeIn("slow");
  });
});

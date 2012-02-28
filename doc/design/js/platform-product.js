$(document).ready(function() { 
	/*$("#myTable").tablesorter({ 
		headers: { 
			1: { 
				sorter: false 
			}
		} 
	});
	*/
	
	$("img.delete-row").click(function(){ 
		var row = this.id.split("delete-")[1];
		$("#"+row).fadeOut("slow");
	});
	
	
});

$(document).ready(function() { 
	$("#myTable").tablesorter({ 
		headers: { 
			1: { 
				sorter: false 
			}, 
			2: { 
				sorter: false 
			} 
		} 
	}); 
});

function deleteRow(num) {
	$("#Row"+num).fadeOut("slow");
}
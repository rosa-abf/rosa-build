$(function(){

	// Datepicker
	$('.datepicker').datepicker({
		showOtherMonths: true,
		selectOtherMonths: true,
		inline: true
	});
	
});

$(document).ready(function() { 
	/*$("#myTable").tablesorter({ 
		headers: { 
			6: { 
				sorter: false 
			}
		} 
	});*/
	
	$("img.delete-row").click(function() {
		var row = this.id.split("delete-")[1];
		$("#"+row).fadeOut("slow");
	});
});
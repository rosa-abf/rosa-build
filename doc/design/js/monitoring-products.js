$(function(){

	// Datepicker
	$('.datepicker').datepicker({
		showOtherMonths: true,
		selectOtherMonths: true,
		inline: true
	});
	
});

$(document).ready(function() { 
	$("#myTable").tablesorter({ 
		headers: { 
			3: { 
				sorter: false 
			}
		} 
	});
});
$(document).ready(function() { 
			$("#selSearch").change(function() {
				var selection = document.getElementById("selSearch").value;
				if (selection == "all") {
					$("#projects").fadeOut(0);
					$("#platforms").fadeOut(0);
					$("#users").fadeOut(0);
					$("#all").fadeIn("fast");
				}
				if (selection == "projects") {
					$("#all").fadeOut(0);
					$("#platforms").fadeOut(0);
					$("#users").fadeOut(0);
					$("#projects").fadeIn("fast");
				}
				if (selection == "users") {
					$("#all").fadeOut(0);
					$("#projects").fadeOut(0);
					$("#platforms").fadeOut(0);
					$("#users").fadeIn("fast");
				}
				if (selection == "platforms") {
					$("#all").fadeOut(0);
					$("#projects").fadeOut(0);
					$("#users").fadeOut(0);
					$("#platforms").fadeIn("fast");
				}
			});
			
			$("#projects-more").click(function() {
				$("#row1-1").fadeIn("fast");
				$("#row1-2").fadeIn("fast");
			});
			
			$("#users-more").click(function() {
				$("#row2-1").fadeIn("fast");
				$("#row2-2").fadeIn("fast");
			});
			
			$("#platforms-more").click(function() {
				$("#row3-1").fadeIn("fast");
				$("#row3-2").fadeIn("fast");
			});
			
		});
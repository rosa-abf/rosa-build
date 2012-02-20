$(document).ready(function() {
  $("#closed-switcher").live('click', function() {
    if ($("#blue-switch-select").css("margin-left") != "130px") {
      $("#blue-switch-select").animate({"margin-left": "+=130px"}, "fast");
      $("#table1").fadeOut(0);
      $("#table2").fadeIn("slow");
      var status = 'closed'
    }
    else {
      $("#blue-switch-select").animate({"margin-left": "-=130px"}, "fast");
      $("#table2").fadeOut(0);
      $("#table1").fadeIn("slow");
      var status = 'open'
    }
    var form = $('#filter_issues');
    $.ajax({
      type: "GET",
      url: form.attr("action"),
      data: form.serialize() + '&status=' + status,
      success: function(data){
        $('article').html(data);
        $(".niceRadio").each(function() { changeRadioStart(jQuery(this)) });
      }
    });
  });
});


$(document).ready(function() {
$("#myTable").tablesorter({
  headers: {
    1: {
      sorter: false
    }
  }
});
});

$(document).ready(function() {
$("#myTable2").tablesorter({
	headers: {
		1: {
			sorter: false
		}
	}
});
});

$(document).ready(function() {
  $("#manage-labels").click(function() {
	$("#labels-stock").fadeOut(0);
	$("#labels-edit").fadeIn("slow");
  });
});

$(document).ready(function() {
  $("div.delete").click(function() {
	var div = "#label-"+this.id;
	$(div).fadeOut("slow");
  });
});

$(document).ready(function() {
  $("div.div-tracker-lables").click(function() {
  var flag = this.id;
  flag = flag.replace("label-","flag-");
  var bg = $("#"+flag).css("background-color");
  if ($(this).css("background-color") != bg) {
    $(this).css("background-color",bg);
    $(this).css("color","#FFFFFF");
    var labels = document.getElementsByName("label");
    var rows = document.getElementsByName("row");
    var arrayLabels;
    var rowState = 0;
    for (var r in rows) {
      for (var l in labels) {
        var ro = document.getElementById(rows[r].id);
        var cls = ro.className;
        var clsLabel = labels[l].id.split("label-")[1];
        if (($("#"+labels[l].id).css("background-color") != "rgb(247, 247, 247)")&&($("#"+labels[l].id).css("background-color") != "transparent")) {
          if (cls.indexOf(clsLabel) != -1) {
            rowState = 1;
          }
        }
      }
      if (rowState == 1) {
        showRow(rows[r].id);
        rowState = 0;
      }
      else {
        hideRow(rows[r].id);
      }
    }
  } else {
    $(this).css("background-color","rgb(247, 247, 247)");
    $(this).css("color","#565657");
    var labels = document.getElementsByName("label");
    var rows = document.getElementsByName("row");
    var rowState = 0;
    var labelState = 0;
    for (var l in labels) {
      if (($("#"+labels[l].id).css("background-color") != "rgb(247, 247, 247)")&&($("#"+labels[l].id).css("background-color") != "transparent")) {
        labelState = 1;
      }
    }
    if (labelState == 1) {
      for (var r in rows) {
        for (var l in labels) {
          var ro = document.getElementById(rows[r].id);
          var cls = ro.className;
          var clsLabel = labels[l].id.split("label-")[1];
          if (($("#"+labels[l].id).css("background-color") != "rgb(247, 247, 247)")&&($("#"+labels[l].id).css("background-color") != "transparent")) {
            if (cls.indexOf(clsLabel) != -1) {
              rowState = 1;
            }
          }
        }
        if (rowState == 1) {
          showRow(rows[r].id);
          rowState = 0;
        }
        else {
          hideRow(rows[r].id);
        }
      }
    } else {
      for (var r in rows) {
        showRow(rows[r].id);
      }
    }
  }
  });
});


function showRow(elem) {
	if ($("#"+elem).css("display") == "none") {
		$("#"+elem).fadeIn("slow");
	} else {
		//$("#"+elem).fadeOut(0);
	}
}

function hideRow(elem) {
  if ($("#"+elem).css("display") != "none") {
    $("#"+elem).fadeOut("fast");
  } else {
    //$("#"+elem).fadeOut(0);
  }
}

$(document).ready(function() {
  $("#myradio1").live('change', function(event) {
    var form = $('#filter_issues');
    $.ajax({
      type: "GET",
      url: form.attr("action"),
      data: form.serialize(),
      success: function(data){
        $('article').html(data);
        $(".niceRadio").each(function() { changeRadioStart(jQuery(this)) });
      }
    });
    return false;
  });

  $('#search_issue').live('submit', function() {
     $.ajax({
       type: "GET",
       url: $(this).attr("action"),
       data: $(this).serialize(),
       success: function(data){
          $('article').html(data);
          $(".niceRadio").each(function() { changeRadioStart(jQuery(this)) });
       }
     });
     return false;
  });
});

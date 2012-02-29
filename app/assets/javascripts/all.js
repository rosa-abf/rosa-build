$(document).ready(function() {
  var dropbox = $("#droplist");

  function loadMessages() {
    $("#messages-new").fadeOut("slow");
    $("#new-messages").delay(700).fadeIn("slow");
  }

  function loadOldMessages() {
    $("#old-messages").fadeIn("slow");
  }

  $(document).click(function() {
    var dl = dropbox.css("height");
    var dl2 = dropbox.css("display");
    if ((dl2 == "block")&&(dl == "91px")) {
      dropbox.slideUp("slow");
    }
  });

  function showActivity(elem) {
    $("#activity-bottom"+elem).slideToggle("slow");
    var img = document.getElementById("expand" + elem).className;
    if (img == "expand-gray-down") {
      document.getElementById("expand" + elem).className = "expand-gray-up";
    } else {
      document.getElementById("expand" + elem).className = "expand-gray-down";
    }
  }

  $('div.information > div.user').live('click', function() {
    dropbox.slideToggle("slow");
  });
});

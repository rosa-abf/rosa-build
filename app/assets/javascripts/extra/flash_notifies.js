function setCookie (name, value, expires, path, domain, secure) {
  document.cookie = name + "=" + escape(value) +
    ((expires) ? "; expires=" + expires : "") +
    ((path) ? "; path=" + path : "") +
    ((domain) ? "; domain=" + domain : "") +
    ((secure) ? "; secure" : "");
}

$(document).ready(function() {
  if ($(".alert").size()) {
    $(".alert").alert()
  }

  $('#close-alert').click(function () {
    var exdate=new Date();
    exdate.setDate(exdate.getDate() + 365);
    var expires="expires="+exdate.toUTCString();
    setCookie("flash_notify_hash", FLASH_HASH_ID, expires);
  });
});


$(document).ready(function() {
  var git_protocol_btn = $('.git-protocol-selector.btn');
  var http_url_in_help = $('.http_url');
  var ssh_url_in_help = $('.ssh_url');

  git_protocol_btn.on('click', function (e) {
    var text = $('#'+$(this).val()).val();
    git_protocol_btn.removeClass('active');
    $('#url.name').val(text);
    $(this).addClass('active');
    if($(this).val() == 'http_url') {
      ssh_url_in_help.addClass('hidden');
      http_url_in_help.removeClass('hidden');
    }
    else {
      http_url_in_help.addClass('hidden');
      ssh_url_in_help.removeClass('hidden');
    }
  });
});

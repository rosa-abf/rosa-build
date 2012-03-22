//= require jquery

$(document).ready(function() {
  var login_default = $('#login_default').val();
  var pass_default = $('#password_default').val();

  $('.registartion-input').live('keydown', function() {
    var id = $(this).attr('id');
     if(id == 'user_login' || id == 'user_password') { id = 'login_error'}
    $('.error.'+id).fadeOut('slow');
  }).live('focus', function() {
    var id = $(this).attr('id');
    if(id == 'user_login' && $(this).val() == login_default) { $(this).val('')}
    else if(id == 'user_password' && $(this).val() == pass_default) { $(this).val('')}
    $(this).addClass('registartion-input-focus').removeClass('registartion-input-error');
  }).live('blur', function() {
    var id = $(this).attr('id');
    if(id == 'user_login' && $(this).val() == '') { $(this).val(login_default)}
    else if(id == 'user_password' && $(this).val() == '') { $(this).val(pass_default)}
    $(this).addClass('registartion-input-no-focus').removeClass('registartion-input-focus');
  });

  $('#niceCheckbox1').click(function() {
    var el = $(this),
          input = el.find('input[type="checkbox"]');
    if(input.attr("checked")) {
      el.css('backgroundPosition', '0 0');
      input.removeAttr('checked');
    } else {
      el.css('backgroundPosition', '0 -18px');
      input.attr('checked', true);
    }
     return true;
  });
});

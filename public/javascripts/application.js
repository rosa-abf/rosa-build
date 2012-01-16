function disableNotifierCbx(global_cbx) {
  if ($(global_cbx).attr('checked')) {
    $('.notify_cbx').removeAttr('disabled');
    $('.notify_cbx').each(function(i,el) { $(el).prev().removeAttr('disabled'); })
  } else {
    $('.notify_cbx').attr('disabled', 'disabled');
    $('.notify_cbx').each(function(i,el) { $(el).prev().attr('disabled', 'disabled'); })
  }
}

$(document).ready(function() {
	$('select#build_list_pl_id').change(function() {
	  var platform_id = $(this).val();
	  var base_platforms = $('.base_platforms input[type=checkbox]');

    $('#include_repos').html($('.preloaded_include_repos .include_repos_' + platform_id).html());

    base_platforms.each(function(){
      if ($.inArray(platform_id, base_platforms.map(function(){ return $(this).val() }).get()) >= 0) {
        if ($(this).val() == platform_id) {
          $(this).attr('checked', 'checked');
          $(this).removeAttr('disabled');
        } else {
          $(this).removeAttr('checked');
          $(this).attr('disabled', 'disabled');
        }
      } else {
        $(this).removeAttr('disabled');
      }
    });
	});
	$('select#build_list_pl_id').trigger('change');

	$('input.user_role_chbx').click(function() {
		var current = $(this);
		current.parent().find('input.user_role_chbx').each(function(i,el) {
			if ($(el).attr('id') != current.attr('id')) {
				$(el).removeAttr('checked');	
			}
		});
	});

  $('#settings_notifier_can_notify').click(function() {
    disableNotifierCbx($(this));
  });
});

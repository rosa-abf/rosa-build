$(document).ready(function() {
	$('select#build_list_pl_id').change(function() {
	  var platform_id = $(this).val();

    $('#include_repos').html($('.preloaded_include_repos .include_repos_' + platform_id).html());

    // var is_pl_main = false;
    // var granted_bpl_id = '';
    // var pl_id = $('select#build_pl').val();
    // 
    // $('input.build_bpl_ids').each(function(i,el) {
    //   var bpl_id = $(el).attr('bpl_id');
    //   if (pl_id == bpl_id) {
    //     is_pl_main = true;
    //     //granted_bpl_id = $(el).attr('bpl_id');
    //   }
    // });
    // 
    // if (is_pl_main) {
    //   $('input.build_bpl_ids').attr('disabled', 'disabled');
    //   $('input.build_bpl_ids[bpl_id="'+pl_id+'"]').removeAttr('disabled');      
    // } else {
    //   $('input.build_bpl_ids').removeAttr('disabled');
    // }
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
});

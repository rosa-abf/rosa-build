function check_by_ids(ids) {
    for(var i = 0; i < ids.length; i++){
        $('#'+ids[i]).attr('checked', true);
    }
    return false;
}

function uncheck_by_ids(ids) {
    for(var i = 0; i < ids.length; i++){
        $('#'+ids[i]).attr('checked', false);
    }
    return false;
}

$(document).ready(function() {
	$('.pl_ids_container input[type="hidden"]').remove();
	
	$('select#build_pl').change(function() {
	  var is_pl_main = false;
	  var granted_bpl_id = '';
	  var pl_id = $('select#build_pl').val();

	  $('input.build_bpl_ids').each(function(i,el) {
	    var bpl_id = $(el).attr('bpl_id');
	    if (pl_id == bpl_id) {
	      is_pl_main = true;
	      //granted_bpl_id = $(el).attr('bpl_id');
	    }
	  });

	  if (is_pl_main) {
	    $('input.build_bpl_ids').attr('disabled', 'disabled');
	    $('input.build_bpl_ids[bpl_id="'+pl_id+'"]').removeAttr('disabled');      
	  } else {
	    $('input.build_bpl_ids').removeAttr('disabled');
	  }
	});

	$('select#build_pl').trigger('change'); 

	$('input.user_role_chbx').click(function() {
		var current = $(this);
		current.parent().find('input.user_role_chbx').each(function(i,el) {
			if ($(el).attr('id') != current.attr('id')) {
				$(el).removeAttr('checked');	
			}
		});
	});
});

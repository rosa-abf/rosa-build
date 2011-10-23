$(document).ready(function() {
	$('.pl_ids_container input[type="hidden"]').remove();
	
	$('select#build_bpl').change(function() {
	  var is_bpl_main = false;
	  var granted_pl_id = '';
	  var bpl_id = $('select#build_bpl').val();

	  $('input.build_pl_ids').each(function(i,el) {
	    var pl_id = $(el).attr('pl_id');
	    if (pl_id == bpl_id) {
	      is_bpl_main = true;
	      //granted_pl_id = $(el).attr('pl_id');
	    }
	  });

	  if (is_bpl_main) {
	    $('input.build_pl_ids').attr('disabled', 'disabled');
	    $('input.build_pl_ids[pl_id="'+bpl_id+'"]').removeAttr('disabled');      
	  } else {
	    $('input.build_pl_ids').removeAttr('disabled');
	  }
	});

	$('select#build_bpl').trigger('change'); 
});
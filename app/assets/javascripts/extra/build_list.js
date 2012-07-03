$(document).ready(function() {
  // TODO: Refactor this handler!! It's too complicated.
  $('#build_list_save_to_platform_id').change(function() {
    var platform_id = $(this).val();
    var base_platforms = $('.all_platforms input[type=checkbox].build_bpl_ids');

    base_platforms.each(function(){
      if ($.inArray(platform_id, base_platforms.map(function(){ return $(this).val() }).get()) >= 0) {
        if ($(this).val() == platform_id) {
          if ($(this).attr('data-released') === '1') {
            $('#build_list_auto_publish').removeAttr('checked').attr('disabled', 'disabled');
            disableUpdateTypes();
          } else {
            $('#build_list_auto_publish').removeAttr('disabled').attr('checked', 'checked');
            enableUpdateTypes();
          }

          $(this).attr('checked', 'checked').removeAttr('disabled').trigger('change');
          $(this).parent().find('.offset25 input[type="checkbox"]').removeAttr('disabled');

          var rep_name = $('#build_list_save_to_platform_id option[value="' + $(this).val() + '"]').text().match(/[\w-]+\/([\w-]+)/)[1];
          if (rep_name != 'main') {
            $(this).parent().find('.offset25 input[type="checkbox"][rep_name="' + rep_name + '"]').attr('checked', 'checked');
          }
          $(this).parent().find('.offset25 input[type="checkbox"][rep_name="main"]').attr('checked', 'checked');
        } else {
          $(this).removeAttr('checked').attr('disabled', 'disabled').trigger('change');
          $(this).parent().find('.offset25 input[type="checkbox"]').attr('disabled', 'disabled').removeAttr('checked');
        }
      } else {
        $(this).removeAttr('disabled').removeAttr('checked').trigger('change');
        $(this).parent().find('.offset25 input[type="checkbox"]').removeAttr('disabled').removeAttr('checked');
        $('#build_list_auto_publish').removeAttr('disabled').attr('checked', 'checked');
      }
    });

    if ($.inArray(platform_id, base_platforms.map(function(){ return $(this).val() }).get()) == -1) {
      // For personal platforms update types always enebaled:
      enableUpdateTypes();
    }


    setBranchSelected();
  });
  $('#build_list_save_to_platform_id').trigger('change');

  $('.offset25 label').click(function() {
    setPlChecked($(this).prev()[0], !$(this).prev().attr('checked'));
  });
  $('.offset25 input[type="checkbox"]').click(function() {
    setPlChecked(this, $(this).attr('checked'));
  });

  $('.build_bpl_ids').click(function() {
    return false;
  });

});

function setPlChecked(pointer, checked) {
  var pl_cbx = $(pointer).parent().parent().parent().find('input[type="checkbox"].build_bpl_ids');
  var pl_id = pl_cbx.val();
  if (checked && !$(pointer).attr('disabled')) {
    pl_cbx.attr('checked', 'checked').trigger('change');
  } else if ($('input[pl_id=' + pl_id + '][checked="checked"]').size() == 0) {
    pl_cbx.removeAttr('checked').trigger('change');
  }
}

function setBranchSelected() {
  var pl_id = $('#build_list_save_to_platform_id').val();
  // Checks if selected platform is main or not:
  if ( $('.all_platforms').find('input[type="checkbox"][value=' + pl_id + '].build_bpl_ids').size() > 0 ) {
    var pl_name = $('#build_list_save_to_platform_id option[value="' + pl_id + '"]').text().match(/([\w-.]+)\/[\w-.]+/)[1];
    var branch_pl_opt = $('#build_list_project_version option[value="latest_' + pl_name + '"]');
    // If there is branch we need - set it selected:
    if ( branch_pl_opt.size() > 0 ) {
      $('#build_list_project_version option[selected]').removeAttr('selected');
      branch_pl_opt.attr('selected', 'selected');
    }
  }
}

function disableUpdateTypes() {
  $("select#build_list_update_type option").each(function(i,el) {
    if ( $.inArray($(el).attr("value"), ["security", "bugfix"]) == -1 ) {
      $(el).attr("disabled", "disabled");
      // If disabled option is selected - select 'bugfix':
      if ( $(el).attr("selected") ) {
        $( $('select#build_list_update_type option[value="bugfix"]') ).attr("selected", "selected");
      }
    }
  });
}

function enableUpdateTypes() {
  $("select#build_list_update_type option").removeAttr("disabled");
}

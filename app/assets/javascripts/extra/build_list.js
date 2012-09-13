$(document).ready(function() {
  // TODO: Refactor this handler!! It's too complicated.
  $('#build_list_save_to_repository_id').change(function() {
    var selected_option = $(this).find("option:selected");

    var platform_id = selected_option.attr('platform_id');
    var rep_name = selected_option.text().match(/[\w-]+\/([\w-]+)/)[1];
    var base_platforms = $('.all_platforms input[type=checkbox].build_bpl_ids');

    base_platforms.each(function(){
      var offset25 = $(this).parent().find('.offset25');
      if ($.inArray(platform_id, base_platforms.map(function(){ return $(this).val(); }).get()) >= 0) {
        if ($(this).val() == platform_id) {
          $(this).attr('checked', 'checked').attr('disabled', 'disabled').trigger('change');
          offset25.find('input[type="checkbox"]').removeAttr('disabled');

          if (rep_name != 'main') {
            offset25.find('input[type="checkbox"][rep_name="' + rep_name + '"]').attr('checked', 'checked');
          }
          offset25.find('input[type="checkbox"][rep_name="main"]').attr('checked', 'checked');
        } else {
          $(this).removeAttr('checked').attr('disabled', 'disabled').trigger('change');
          offset25.find('input[type="checkbox"]').attr('disabled', 'disabled').removeAttr('checked');
        }
      } else {
        $(this).removeAttr('disabled').removeAttr('checked').trigger('change');
        offset25.find('input[type="checkbox"]').removeAttr('disabled').removeAttr('checked');
      }
    });

    if ($.inArray(platform_id, base_platforms.map(function(){ return $(this).val(); }).get()) === -1) {
      // For personal platforms update types always enebaled:
      enableUpdateTypes();
    }


    setBranchSelected();
    checkAccessToAutomatedPublising();
  });

  $('#build_list_save_to_repository_id').trigger('change');

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

function getSaveToRepositoryOption() {
  return $('#build_list_save_to_repository_id option:selected');
}

function checkAccessToAutomatedPublising() {
  if (getSaveToRepositoryOption().attr('publish_without_qa') == '1') {
    $('#build_list_auto_publish').removeAttr('disabled').attr('checked', 'checked');
  } else {
    $('#build_list_auto_publish').removeAttr('checked').attr('disabled', 'disabled');
  }
}

function setPlChecked(pointer, checked) {
  var pl_cbx = $(pointer).parent().parent().parent().find('input[type="checkbox"].build_bpl_ids');
  var pl_id = pl_cbx.val();
  if (checked && !$(pointer).attr('disabled')) {
    pl_cbx.attr('checked', 'checked').trigger('change');
  } else if ($('input[save_to_platform_id=' + pl_id + '][checked="checked"]').size() === 0) {
    pl_cbx.removeAttr('checked').trigger('change');
  }
}

function setBranchSelected() {
  var selected_option = getSaveToRepositoryOption();
  var pl_id = selected_option.attr('platform_id');
  // Checks if selected platform is main or not:
  if ( $('.all_platforms').find('input[type="checkbox"][value=' + pl_id + '].build_bpl_ids').size() > 0 ) {
    var pl_name = selected_option.text().match(/([\w-.]+)\/[\w-.]+/)[1];
    var branch_pl_opt = $('#build_list_project_version option[value="latest_' + pl_name + '"]');
    // If there is branch we need - set it selected:
    if ( branch_pl_opt.size() > 0 ) {
      $('#build_list_project_version option[selected]').removeAttr('selected');
      branch_pl_opt.attr('selected', 'selected');
      var bl_version_sel = $('#build_list_project_version');
      bl_version_sel.val(branch_pl_opt);
      // hack for FF to force render of select box.
      bl_version_sel[0].innerHTML = bl_version_sel[0].innerHTML;
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

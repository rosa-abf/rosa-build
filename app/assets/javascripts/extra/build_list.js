$(document).ready(function() {
  $('#build_list_pl_id').change(function() {
    var platform_id = $(this).val();
    var base_platforms = $('.all_platforms input[type=checkbox].build_bpl_ids');

    base_platforms.each(function(){
      if ($.inArray(platform_id, base_platforms.map(function(){ return $(this).val() }).get()) >= 0) {
        if ($(this).val() == platform_id) {
          $(this).attr('checked', 'checked').removeAttr('disabled');
          $(this).parent().find('.offset25 input[type="checkbox"]').removeAttr('disabled');

          var rep_name = $('#build_list_pl_id option[value="' + $(this).val() + '"]').text().match(/[\w-]+\/([\w-]+)/)[1];
          if (rep_name != 'main') {
            $(this).parent().find('.offset25 input[type="checkbox"][rep_name="' + rep_name + '"]').attr('checked', 'checked');
          }
          $(this).parent().find('.offset25 input[type="checkbox"][rep_name="main"]').attr('checked', 'checked');
        } else {
          $(this).removeAttr('checked').attr('disabled', 'disabled');
          $(this).parent().find('.offset25 input[type="checkbox"]').attr('disabled', 'disabled').removeAttr('checked');
        }
      } else {
        $(this).removeAttr('disabled').removeAttr('checked');
        $(this).parent().find('.offset25 input[type="checkbox"]').removeAttr('disabled').removeAttr('checked');
      }
    });
  });
  $('#build_list_pl_id').trigger('change');

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
    pl_cbx.attr('checked', 'checked');
  } else if ($('input[pl_id=' + pl_id + '][checked="checked"]').size() == 0) {
    pl_cbx.removeAttr('checked');
  }
}

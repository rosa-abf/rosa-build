$(document).ready(function() {
  $('#build_list_pl_id').change(function() {
    var platform_id = $(this).val();
    var base_platforms = $('.all_platforms input[type=checkbox].build_bpl_ids');

    //$('#include_repos').html($('.preloaded_include_repos .include_repos_' + platform_id).html());

    base_platforms.each(function(){
      if ($.inArray(platform_id, base_platforms.map(function(){ return $(this).val() }).get()) >= 0) {
        if ($(this).val() == platform_id) {
          $(this).attr('checked', 'checked');
          $(this).removeAttr('disabled');
          $(this).parent().find('.offset25 input[type="checkbox"]').removeAttr('disabled');
          if ($(this).parent().find('.offset25 label').text() == 'main') {
            $(this).parent().find('.offset25 input[type="checkbox"]').attr('checked', 'checked');
          }
        } else {
          $(this).removeAttr('checked');
          $(this).attr('disabled', 'disabled');
          $(this).parent().find('.offset25 input[type="checkbox"]').attr('disabled', 'disabled');
          $(this).parent().find('.offset25 input[type="checkbox"]').removeAttr('checked');
        }
        //$('.additional_pl').parent().find('.offset25 input[type="checkbox"]').attr('disabled', 'disabled');
      } else {
        $(this).removeAttr('disabled');
        $(this).removeAttr('checked');
        $(this).parent().find('.offset25 input[type="checkbox"]').removeAttr('disabled');
        $(this).parent().find('.offset25 input[type="checkbox"]').removeAttr('checked');
        //$('.additional_pl').parent().find('.offset25 input[type="checkbox"]').removeAttr('disabled');
      }
    });
  });
  $('#build_list_pl_id').trigger('change');
});

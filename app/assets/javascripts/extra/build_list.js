$(document).ready(function() {
  $('#build_list_pl_id').change(function() {
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
  $('#build_list_pl_id').trigger('change');
});

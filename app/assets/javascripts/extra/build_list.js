$(document).ready(function() {
  // TODO: Refactor this handler!! It's too complicated.
  $('#build_list_save_to_repository_id').change(function() {
    var selected_option = $(this).find("option:selected");

    var platform_id = selected_option.attr('platform_id');
    var rep_name = selected_option.text().match(/[\w-]+\/([\w-]+)/)[1];

    var build_platform = $('#build_for_pl_' + platform_id);
    var all_repositories = $('.all_platforms input');
    all_repositories.removeAttr('checked');
    if (build_platform.length == 0) {
      all_repositories.removeAttr('disabled');
    } else {
      all_repositories.attr('disabled', 'disabled');
      var parent = build_platform.parent();
      parent.find('input').removeAttr('disabled');
      parent.find('input[rep_name="main"]').attr('checked', 'checked');
      if (rep_name != 'main') {
        parent.find('input[rep_name="' + rep_name + '"]').attr('checked', 'checked');
      }
    }
    var build_list_auto_publish = $('#build_list_auto_publish');
    if (selected_option.attr('publish_without_qa') == '1') {
      build_list_auto_publish.removeAttr('disabled').attr('checked', 'checked');
    } else {
      build_list_auto_publish.removeAttr('checked').attr('disabled', 'disabled');
    }
  });

  $('#build_list_save_to_repository_id').trigger('change');
});

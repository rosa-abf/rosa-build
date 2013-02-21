$(document).ready(function() {
  // TODO: Refactor this handler!! It's too complicated.
  $('#build_list_save_to_repository_id').change(function() {
    var selected_option = $(this).find("option:selected");

    var platform_id = selected_option.attr('platform_id');
    var rep_name = selected_option.text().match(/[\w-]+\/([\w-]+)/)[1];

    var build_platform = $('#build_for_pl_' + platform_id);
    var all_repositories = $('.all_platforms input');
    all_repositories.removeAttr('checked');
    var use_save_to_repository = $('#build_list_use_save_to_repository');

    if (build_platform.size() == 0) {
      all_repositories.removeAttr('disabled');
      use_save_to_repository.removeAttr('disabled');
    } else {
      updateExtraReposAndContainers();
      use_save_to_repository.attr('disabled', 'disabled').attr('checked', 'checked');
      all_repositories.attr('disabled', 'disabled');
      var parent = build_platform.parent();
      parent.find('input').removeAttr('disabled');
      parent.find('input[rep_name="main"]').attr('checked', 'checked');
      if (rep_name != 'main') {
        parent.find('input[rep_name="' + rep_name + '"]').attr('checked', 'checked');
      }
      setBranchSelected(selected_option);
    }
    var build_list_auto_publish = $('#build_list_auto_publish');
    if (selected_option.attr('publish_without_qa') == '1') {
      build_list_auto_publish.removeAttr('disabled').attr('checked', 'checked');
    } else {
      build_list_auto_publish.removeAttr('checked').attr('disabled', 'disabled');
    }

    var path = '/build_lists/autocomplete_to_extra_repos_and_containers?platform_id=' + platform_id;
    $('#extra_repos').attr('data-autocomplete', path);
  });

  $('#build_list_save_to_repository_id').trigger('change');

  $('#extra-repos-and-containers #add').click(function() {
    updateExtraReposAndContainers();
    return false;
  });

  $(document).on('click', '#extra-repos-and-containers .delete', function() {
    $(this)[0].parentElement.parentElement.remove();
  });

  $('#extra-repos-and-containers-dialog').dialog({
    autoOpen: false,
    resizable: false,
    width: 400
  });

  $('#extra-repos-and-containers .icon-question-sign').click(function() {
    var dialog = $('#extra-repos-and-containers-dialog');
    if (dialog.is(':visible')) { dialog.dialog('close'); } else { dialog.dialog('open'); }
  });

});

function updateExtraReposAndContainers() {
  $.get("/build_lists/update_extra_repos_and_containers", $('#new_build_list').serialize())
  .done(function(data) {
    $("#extra-repos-and-containers table tbody").html(data);
  });
}

function setBranchSelected(selected_option) {
  var pl_name = selected_option.text().match(/([\w-.]+)\/[\w-.]+/)[1];
  var bl_version_sel = $('#build_list_project_version');
  var branch_pl_opt = bl_version_sel.find('option[value="' + pl_name + '"]');
  // If there is branch we need - set it selected:
  if (branch_pl_opt.size() > 0) {
    bl_version_sel.find('option[selected]').removeAttr('selected');
    branch_pl_opt.attr('selected', 'selected');
    bl_version_sel.val(branch_pl_opt);
    // hack for FF to force render of select box.
    bl_version_sel[0].innerHTML = bl_version_sel[0].innerHTML;
  }
}

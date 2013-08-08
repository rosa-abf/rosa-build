$(document).ready(function() {
  var new_form      = $('#new_form');
  var ownership_btn = $('.btn.ownership');
  var perpage_btn   = $('.btn.per_page');

  // TODO: Refactor this handler!! It's too complicated.
  $(document).on('change', '#build_list_save_to_repository_id', function(){
    var selected_option = $(this).find("option:selected");
    var platform_id = selected_option.attr('platform_id');
    var rep_name = selected_option.text().match(/[\w-]+\/([\w-]+)/)[1];

    var build_platform = $('#build_for_pl_' + platform_id);
    var all_repositories = $('.all_platforms input');
    all_repositories.removeAttr('checked');
    var auto_create_container = $('#build_list_auto_create_container');
    var extra_repos = $('.autocomplete-form.extra_repositories');

    updateExtraReposAndBuildLists(platform_id);
    updatedDefaultArches(selected_option);
    $('.autocomplete-form table tbody').empty();
    if (build_platform.size() == 0) {
      all_repositories.removeAttr('disabled');
      auto_create_container.removeAttr('checked');
      addPersonalPlatformToExtraRepos(selected_option, extra_repos);
      extra_repos.show();
    } else {
      all_repositories.attr('disabled', 'disabled');
      extra_repos.hide();
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
      auto_create_container.attr('checked', 'checked');
    }
  });

  if($('#from_build_list_id').size() == 0) {
    $('#build_list_save_to_repository_id').trigger('change');
  }

  ownership_btn.click(function() {
    ownership_btn.removeClass('active');
    $('#filter_ownership').val($(this).val());
    $(this).addClass('active');
    return false;
  });

  perpage_btn.click(function() {
    perpage_btn.removeClass('active');
    $('#per_page').val($(this).val());
    $(this).addClass('active');
    return false;
  });

  $('a#updated_at_clear').click(function() {
    $($(this).attr('href')).val('');
    return false;
  });

  $('#filter_clear').click(function() {
    $('#monitoring_filter .input_cleanse').val('');
    $('.btn-group .btn').removeClass('active');
    if(ownership_btn.length > 0) { ownership_btn[0].click(); }
    perpage_btn[0].click();
    return false;
  });

  $('.mediumheight.min').datepicker({
    dateFormat: 'dd/mm/yy',
    showButtonPanel: true
  });

  $(document).on('change', '#owner_filter_build_lists, #status_filter_build_lists', function(){
    $('#datatable').dataTable().fnDraw();
  });

  $(document).on('click', '#clone_build_list', function() {
    $.ajax({
      type: 'GET',
      url: $(this).attr('href') + '&show=inline',
      success: function(data){
                 new_form.html(data);
                 $(document).scrollTop(new_form.offset().top);
               },
      error: function(data){
               alert('error') // TODO remove
             }
     });
    return false;
  });
});

function updatedDefaultArches(selected_option) {
  $('input[name="arches[]"]').removeAttr('checked');
  _.each(selected_option.attr('default_arches').split(' '), function(id){
    $('#arches_' + id).attr('checked', 'checked');
  });
}

function updateExtraReposAndBuildLists(save_to_platform_id) {
  $.each($('.autocomplete-form'), function() {
    var form = $(this);
    var path = form.attr('path') + '?platform_id=' + save_to_platform_id;
    form.find('.autocomplete').attr('data-autocomplete', path);
  });
}

function addPersonalPlatformToExtraRepos(selected_option, extra_repos) {
  var default_value = extra_repos.find('div[label="' + selected_option.text() + '"]');
  if (default_value.length == 0) { return; }
  addDataToAutocompleteForm(
    extra_repos,
    default_value.attr('path'),
    default_value.attr('label'),
    default_value.attr('name'),
    default_value.attr('value')
  );
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

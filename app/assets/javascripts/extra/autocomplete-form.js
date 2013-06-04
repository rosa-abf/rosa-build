$(document).ready(function() {
  // // TODO: Refactor this handler!! It's too complicated.
  // $('#build_list_save_to_repository_id, #build_for_platform').change(function() {
  //   var selected_option = $(this).find('option:selected');
  //   var platform_id = selected_option.attr('platform_id') || selected_option.val();
  //   var path = '/build_lists/autocomplete_to_extra_repos_and_builds?platform_id=' + platform_id;
  //   $('#extra_repos').attr('data-autocomplete', (path + '&search_repos=true'));
  //   $('#extra_build_lists').attr('data-autocomplete', path);
  // });


  $('.autocomplete-form .button.add').click(function() {
    var form    = $(this).parent();
    var field   = form.attr('field');
    var subject = $('#' + field + '_field');
    if (!subject.val()) { return false; }
    var name  = form.attr('subject_class') + '[' + field + ']' + '[]';
    var path  = $('#' + field + '_field_path').val();
    var label = $('#' + field + '_field_label').val();

    var tr =  '<tr>' +
                '<td>' +
                  '<a href="' + path + '">' + label + '</a>' +
                '</td>' +
                '<td class="actions">' +
                  '<input name="' + name + '" type="hidden" value="' + subject.val() + '">' +
                  '<span class="delete"> </span>' +
                '</td>' +
              '</tr>';

    form.find('table tbody').append($(tr));
    form.find('.autocomplete').val('');
    return false;
  });

  $(document).on('click', '.autocomplete-form .delete', function() {
    $(this).parent().parent().remove();
  });

  $('.autocomplete-form .dialog').dialog({
    autoOpen:   false,
    resizable:  false,
    width:      500
  });

  $('.autocomplete-form .icon-question-sign').click(function() {
    var field = $(this).parent().attr('field');
    var dialog = $('#' + field + '_dialog');
    if (dialog.is(':visible')) { dialog.dialog('close'); } else { dialog.dialog('open'); }
  });

});

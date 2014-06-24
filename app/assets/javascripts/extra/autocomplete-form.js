$(document).ready(function() {

  $(document).on('click', '.autocomplete-form .button.add', function() {
    var form    = $(this).parent();
    var field   = form.attr('field');
    var subject = $('#' + field + '_field');
    if (!subject.val()) { return false; }
    var name  = form.attr('subject_class') + '[' + field + ']' + '[]';
    var path  = $('#' + field + '_field_path').val();
    var label = $('#' + field + '_field_label').val();

    addDataToAutocompleteForm(form, path, label, name, subject.val());
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

  $(document).on('click', '.autocomplete-form .icon-question-sign', function() {
    var field = $(this).parent().attr('field');
    var dialog = $('#' + field + '_dialog');
    if (dialog.is(':visible')) { dialog.dialog('close'); } else { dialog.dialog('open'); }
  });

});

function addDataToAutocompleteForm(form, path, label, name, value) {
  var tr =  '<tr>' +
              '<td>' +
                '<a href="' + path + '">' + label + '</a>' +
                '<div class="actions pull-right">' +
                  '<input name="' + name + '" type="hidden" value="' + value + '">' +
                  '<span class="fa fa-times fa-lg delete text-danger"> </span>' +
              '</td>' +
            '</tr>';
  form.find('table tbody').append($(tr));
}

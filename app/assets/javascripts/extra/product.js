$(document).ready(function() {

  $('#product_project').bind('railsAutocomplete.select', function(event, data){
    var ppv = $("#product_project_version").empty().append('<option value=""></option>');
    $(data.item.project_versions).each(function(k, i) {
      var optgroup = $('<optgroup label="' + i[0] + '"></optgroup>');
      $(i[1]).each(function(k, b) {
        optgroup.append('<option value="' + b + '">' + b + '</option>');
      });
      ppv.append(optgroup);
    });
  });

});
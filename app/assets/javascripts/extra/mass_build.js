$(document).ready(function() {
  var projects_list = $('.form.mass_build #mass_build_projects_list');
  var repositories = $(".form.mass_build .left input:checkbox");
  repositories.click(function(){
    if (this.checked){
      $(this).attr('disabled',true);
      $.ajax({
        type: 'GET',
        url: $(this).attr('href'),
        success: function(data){
                   var text = projects_list.val();
                   if(text.length > 0 && text.slice(-1) != '\n') {text = text + "\n"}
                   projects_list.val(text+data);
                 },
        error: function(data){
                 alert('Error :(') // TODO remove
               }
      });
    }
    return true;
  });

  projects_list.keyup(function(){
    if($(this).val().length == 0) {
      repositories.attr('disabled',false)
                  .attr('checked', false);
    }
  });

  var autocomplete_repos = $('.autocomplete-form.extra_repositories #extra_repositories');
  var default_autocomplete_path = $('#autocomplete_extra_repos_path').val();
  $('#mass_build_build_for_platform_id').on('change', function() {
    var path = default_autocomplete_path + '&build_for_platform_id=' + $(this).val();
    autocomplete_repos.attr('data-autocomplete', path);
  });
  $('#mass_build_build_for_platform_id').trigger('change');
});

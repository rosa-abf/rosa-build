$(document).ready(function() {
  var projects_list = $('.form.mass_build #projects_list');
  var repositories = $(".form.mass_build input:checkbox");
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
});

$(document).ready(function() {
  var new_form      = $('#new_form');


  if($('#from_build_list_id').size() == 0) {
    $('#build_list_save_to_repository_id').trigger('change');
  }

  $(document).on('click', '#owner_filter_build_lists, #status_filter_build_lists', function(){
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

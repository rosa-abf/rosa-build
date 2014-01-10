$(document).ready(function() {
  var fork_name = $('#fork_name');
  var forks_path = $('#possible_forks_path');

  fork_name.keyup(function(){
    $.ajax({
      type: 'GET',
      url: forks_path.val(),
      data: 'name=' + fork_name.val(),
      success: function(data){
        $('#forks_list').html(data);
      },
      error: function(data){
        alert('error'); // TODO remove
      }
    });
  });

});
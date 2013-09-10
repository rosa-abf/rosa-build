$(document).ready(function() {
  var profile_table = $('.profile-table');
  var profile_path = $('#profile_path').text();
  var profile_vis_buttons = $('.profile-content .span12.sub-menu nav a');
  var profile_search_field = $('.profile-content .search #query_projects');

  var load_profile_projects = function (page_number) {
    var visibility = 'visibility=' + ($('.profile-content .span12.sub-menu nav a.active').hasClass('public-projects') ? 'open' : 'hidden');
    var search = 'search=' + profile_search_field.val();
    page = 'page=' + (page_number || $('.pagination .current').text());
    $.ajax({
      type: 'GET',
      url: profile_path,
      data: 'projects=show&' + visibility + '&' + search + '&' + page,
      success: function(data){
                 profile_table.html(data);
                 updateTime();
               },
      error: function(data){
               alert('error') // TODO remove
             }
     });
    return false;
  }

  profile_vis_buttons.live('click', function () {
    profile_vis_buttons.toggleClass('active');
    return load_profile_projects();
  });

  $(document).on('click','.profile-table .pagination a', function(){
    updatePagination($(this));
    return load_profile_projects();
  });

  $('#query_projects').on('keyup', function() {
    var visibility = 'visibility=' + ($('.profile-content .span12.sub-menu nav a.active').hasClass('public-projects') ? 'open' : 'hidden');
    var search = 'search=' + profile_search_field.val();
    data = 'projects=show&' + visibility + '&' + search;
    return search_items(profile_path, data, profile_table);
  });
});


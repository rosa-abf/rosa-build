$(document).ready ->
  $(document).on 'click', '#diff_header .panel-body li.list-group-item a', ->
    href = $(this).attr('href')
    $(".diff_data.collapse#"+href.slice(1)+"_content").collapse('show')

  return

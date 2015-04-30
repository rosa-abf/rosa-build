$(document).ready ->
  $(document).on 'hide.bs.collapse', '.file .diff_data.collapse', ->
    $(this).parent().find('.top button span.fa').removeClass('fa-chevron-down').addClass('fa-chevron-up')

  $(document).on 'show.bs.collapse', '.file .diff_data.collapse', ->
    $(this).parent().find('.top button span.fa').removeClass('fa-chevron-up').addClass('fa-chevron-down')

  $(document).on 'hide.bs.collapse', '#diff_header #collapseList', ->
    $(this).parent().find('.panel-title a span.fa').removeClass('fa-chevron-down').addClass('fa-chevron-up')

  $(document).on 'show.bs.collapse', '#diff_header #collapseList', ->
    $(this).parent().find('.panel-title a span.fa').removeClass('fa-chevron-up').addClass('fa-chevron-down')

  return

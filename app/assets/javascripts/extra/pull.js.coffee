upd_action = $('#update_action').val()
form       = $('#new_pull_request')

updatePull = ->
  form.attr('action', upd_action)
      .attr('method', 'get')
  $('#update_pull').fadeIn('fast')
  $('#create_pull').fadeOut('fast')
  return

window.pullUpdateToProject = (data)->
  ref = $('#to_ref');
  ref.parent().load('/'+data.text+'/refs_list', {"selected": ref.val()})
  updatePull()
  return

$('select#to_ref, select#from_ref').on('change', updatePull)

$('#pull_tabs a').on 'click', (e) ->
  href = $(this).attr('href')
  if window.history and history.pushState
    history.pushState '', '', href
    history.replaceState '', '', href
  else
    location.hash = href
  return

diff_tab = $('#pull_tabs a[href="#diff"]')
$('.link_to_full_changes').on 'click', ->
  diff_tab.tab 'show'
  return

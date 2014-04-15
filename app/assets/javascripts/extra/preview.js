$(document).ready(function() {
  var preview_url = $('#preview_url').val();
  $('#md_tabs.nav.nav-tabs').each(function(i) { $(this).find('a:first').tab('show') });

  $(document).on('shown','#md_tabs a[data-toggle="tab"]', function (e) {
    if(e.relatedTarget) { var hash = e.relatedTarget.hash; }
    else { var hash = e.currentTarget.hash; }
    var el = $(hash+'_input');
    var el_dup = $(hash+'_input_dup');
    var preview = $(e.target.hash+' > .formatted.cm-s-default');
   if(el.val() != el_dup.val() || preview.val() === '') {
     el_dup.val(el.val());
     $.ajax({
       type: 'POST',
       url: preview_url,
       data: el_dup.serialize(),
       success: function(data){
                       preview.html(data);
                }
     });
    };
  });
});

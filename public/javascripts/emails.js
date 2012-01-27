$(function() {

  $("#add_button").click(function(){
    var c = $('.emails').length;
    var clone = $('.emails:first').clone();
    clone.find('input')
      .removeAttr('id').attr("id", "user_emails_attributes_"+c+"_email")
      .removeAttr('name').attr("name", "user[emails_attributes]["+c+"][email]").val('');
    clone.find(".delete_button").attr('href', "#");
    clone.insertAfter('.emails:last');
    return false;
  });

  $("a.delete_button").live("click", function(){
      function del_question() {
        var p = a.parentNode;
        p.parentNode.removeChild(p);
      }
      var a = this;
      if(/#$/.test(a.href)) { del_question(); /* delete new email */}
      else { /* delete exists email */
        $.ajax({
          type: "POST",
          url: this.href,
          //data: "authenticity_token=" + encodeURIComponent(AUTH_TOKEN),
          success: function(msg){
            del_question();
            var q_id = a.href.match(/user\/emails\/(\d+)/);
            if(q_id) {
              var e = $('input:hidden[value='+q_id[1]+']');
              e.remove();
            }
          }
        });
      }
    return false;
  });
});
function initLogWrapper() {
  var $wrapper = $('div.log-wrapper');
  var $logBody = $wrapper.children('div.log-body').first();
  var $logCont = $logBody.children('.log').first();

  var logUrl   = $logCont.data('url');
  var $logHead = $wrapper.children('div.log-header').first();

  var $trigger = $logHead.children('span').first();
  var $autoload = $('#autoreload');

  var state = $logBody.is(':visible');
  var t = null; // timer
  var first_open = true;

  if (state) {
    $trigger.removeClass('closed');
    $wrapper.removeClass('inactive')
            .addClass('active');
  } else {
    $trigger.addClass('closed');
    $logBody.addClass('hidden');
    $wrapper.removeClass('active')
            .addClass('inactive');
  }

  function getLineHeight(element){
    var temp = document.createElement(element.nodeName);
    temp.setAttribute("style","margin:0px;padding:0px;font-family:"+element.style.fontFamily+";font-size:"+element.style.fontSize);
    temp.innerHTML = "test";
    temp = element.parentNode.appendChild(temp);
    var ret = temp.clientHeight;
    temp.parentNode.removeChild(temp);
    return ret;
  }

  var loadLog = function() {
    $.ajax({
      url: logUrl,
      type: "GET",
      dataType: 'json',
      data: $logCont.data(),
      beforeSend: function( xhr ) {
        var token = $('meta[name="csrf-token"]').attr('content');
        if (token) xhr.setRequestHeader('X-CSRF-Token', token);
      },
      success: function(data, textStatus, jqXHR) {
        var l = $logCont[0];
        var vScroll = l.scrollTop;
        var hScroll = l.scrollLeft;
        var onBottom = Math.abs((l.clientHeight + vScroll - l.scrollHeight)) < getLineHeight(l);

        $("#output").html(data.log);
        //CodeMirror.runMode(data.log.replace(/&amp;/gi, '&'), "text/x-sh", document.getElementById("output"));

        $logCont.scrollLeft(hScroll);
        $logCont.scrollTop((onBottom || first_open) ? l.scrollHeight - l.clientHeight : vScroll);
        first_open = false;
        if (!data.building) $autoload.attr({'checked': false}).trigger('change');
      }
    });
  }

  var reloadChange = function() {
    if ($(this).is(':checked')) {
      first_open = true;
      loadLog();
      $logCont.scrollTop($logCont[0].scrollHeight - $logCont[0].clientHeight);
      t = setInterval(function() {
        loadLog();
      }, $('#reload_interval').val());
    } else {
      clearInterval(t);
    }
  }

  var toggleHandler = function() {
    state = !state;
    // if log opened
    if (state) {
      if ($autoload.is(':checked')) {
        $autoload.trigger('change');
      }
    } else {
      clearInterval(t);
    }
    $logBody.slideToggle('slow')
            .toggleClass('hidden');
    $logHead.toggleClass('active inactive');
    $trigger.toggleClass('closed');

    window.location.href = $('a#log_anchor').attr('href');
  }

  $wrapper.on('click', '.log-header > span', toggleHandler);
  $autoload.on('change', reloadChange);

  $('#word_wrap').on('change', function() {
    $logCont.css('white-space', ($(this).is(':checked')) ? 'normal' : 'pre');
  });

  $('#reload_interval').on('change', function() {
    clearInterval(t);
    if ($autoload.is(':checked')) {
      t = setInterval($(this).val());
    }
  });
  loadLog();
}
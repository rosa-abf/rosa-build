var CommentsController = function(Comment, Preview, confirmMessage, $scope, compileHTML, $rootScope) {

  var inlineCommentParams = {};
  var list = null;
  var new_inline_form = $('.new_inline_comment_form.hidden');

  var setInlineCommentParams = function(params) {
    inlineCommentParams = params;
  }

  var findInlineComments = function($event, params) {
    if (params.in_reply) {
      return $('#comment' + params.in_reply).parents('tr').find('td .line-comment:last');
    } else {
      return $($event.target).parents('tr');
    }
  }

  var insertCommentForm = function(line_comments, form) {
    if (inlineCommentParams.in_reply) {
      var new_form = compileHTML.run($scope, form);
      line_comments.append(new_form);
    } else {
      if (line_comments.hasClass('line-comments')) {
        var new_form = form;
        new_form = compileHTML.run($scope, new_form);
        line_comments.find('td.line-comments:last').append(new_form);
      } else {
        var new_form = "<tr class='line-comments'><td class='line_numbers' colspan='2'></td>" +
          "<td>" + form + "</td></tr>";
        new_form = compileHTML.run($scope, new_form);
        line_comments.after(new_form);
      }
    }
    return true;
  }

  var vm = this;

  vm.isDisabledNewInlineCommentButton = function() {
    return vm.processing || vm.new_inline_body === '' || !vm.new_inline_body;
  }

  vm.isDisabledNewCommentButton = function() {
    return vm.processing || vm.new_body === '' || !vm.new_body;
  }

  vm.previewBody = function(id) {
    var body;

    if (id === 'new-comment') {
      body = vm.new_body;
    } else if (id === 'new-inline-comment') {
      body = vm.new_inline_body;
    } else {
      body = $('#' + id + '-body').val();
    }

    if (body === '' || !body) {
      vm.preview_body = '';
      return false;
    }

    if (body === Preview.old_text) {
      return false;
    }

    if (vm.processing) {
      return false;
    }

    vm.processing = true;
    Preview.old_text = '';

    var promise = Preview.get_preview(vm.project, body);
    promise.success(function(response) {
      vm.preview_body = response.html;
      Preview.old_text = body;
    }).error(function(response) {
      vm.preview_body = 'Error :(';
    });

    vm.processing = false;
    return false;
  }

  vm.toggleEditForm = function(id) {
    $('.open-comment').addClass('hidden');
    var form = $('.open-comment.comment-' + id);

    if (form.length === 1) {
      form.removeClass('hidden');
      // Maybe Chrome 43 bug? don't show text in the textarea :(
      var textarea = form.find('.form-group textarea');
      var tmp = textarea.val();
      textarea.val('');
      textarea.val(tmp);
      //////////
      return true;
    } else {
      return false;
    }
  }

  vm.closeEditForm = function(id) {
    $('.open-comment.comment-' + id).addClass('hidden');
    return false;
  }

  vm.add = function($event) {
    $event.preventDefault();
    $event.stopPropagation();

    vm.processing = true;
    Comment.add(vm.project, vm.commentable, vm.new_body)
    .success(function(data) {
      var element = compileHTML.run($scope, data.html);
      list.append(element);

      vm.new_body = '';
      location.hash = "#comment" + data.id;
      vm.processing = false;
      $.notify(data.message, 'success');
    })
    .error(function(data) {
      $.notify(data.message, 'error');
      vm.processing = false;
    });

    return false;
  }

  vm.remove = function(id) {
    if (!confirmMessage.show()) {
      return false;
    }

    vm.processing = true;
    Comment.remove(vm.project, vm.commentable, id)
    .success(function(data) {
      var parent = $('#comment' + id + ',#diff-comment' + id).parents('tr.line-comments');
      if (parent.find('.line-comment').length === 1) {
        // there is only one line comment, remove all line
        parent.remove();
      } else {
        $('#comment' + id + ',#diff-comment' + id + ',#update-comment' + id).remove();
      }

      $.notify(data.message, 'success');
      vm.processing = false;
    })
    .error(function(data) {
      $.notify(data.message, 'error');
      vm.processing = false;
    });

    return false;
  }

  vm.update = function(id) {
    vm.processing = true;
    Comment.update(vm.project, vm.commentable, id)
    .success(function(data) {
      var form = $('#comment' + id + ' .md_and_cm.cm-s-default').html(data.body);

      $.notify(data.message, 'success');
      vm.processing = false;

      var form = $('.open-comment.comment-' + id);
      if (form.length === 1) {
        form.addClass('hidden');
        return true;
      } else {
        return false;
      }
    })
    .error(function(data) {
      $.notify(data.message, 'error');
      vm.processing = false;
    });
  }

  vm.showInlineForm = function($event, params) {
    if (params === undefined) {
      params = {};
    }

    var line_comments = findInlineComments($event, params);
    if (line_comments.count === 0) {
      return false;
    }

    vm.new_inline_body = null;
    vm.hideInlineForm();
    setInlineCommentParams(params);
    insertCommentForm(line_comments, new_inline_form.html());
    var tmp = line_comments.find('#new_inline_comment');
    $('table.table #new_inline_comment').addClass('cloned');
    return true;
  }

  vm.hideInlineForm = function(is_new_comment) {
    if (is_new_comment === undefined) {
      is_new_comment = false;
    }

    var parent = $('#new_inline_comment.cloned').parents('tr.line-comments');
    if (!is_new_comment && parent.find('.line-comment').length === 1) {
      // there is only one line comment, remove all line
      parent.remove();
    } else {
      $('#new_inline_comment.cloned').remove();
    }

    inlineCommentParams = {};
    return false;
  }

  vm.hideInlineCommentButton = function(params) {
    if (params === undefined) {
      params = {};
    }

    return _.isEqual(inlineCommentParams, params);
  }

  vm.addInline = function($event) {
    var line_comments = findInlineComments($event, inlineCommentParams);
    if (line_comments.count === 0) {
      return false;
    }

    vm.processing = true;
    var promise = Comment.addInline(vm.project, vm.commentable, vm.new_inline_body, inlineCommentParams);
    promise.then(function(response) {
      vm.hideInlineForm(true);
      insertCommentForm(line_comments, response.data.html);

      vm.new_inline_body = '';
      location.hash = "#comment" + response.data.id;
      vm.processing = false;
    });

    return false;
  }

  $rootScope.$on("compile_html", function(event, args) {
    var html = compileHTML.run($scope, args.html);
    args.element.html(html);
    return true;
  });

  vm.init = function(project, commentable) {
    if (commentable === undefined) {
      commentable = {};
    }

    vm.project = project;
    vm.commentable = commentable;
    vm.processing = false;
    vm.k = 10;

    if (commentable.kind === 'issue' || commentable.kind === 'commit') {
      list = $('#comments_list');
    } else if (commentable.kind === 'pull') {
      list = $('#pull-activity');
    } else {
      list = $();
    }

    return true;
  }

  return true;
}

angular
  .module("RosaABF")
  .controller("CommentsController", CommentsController);

CommentsController.$inject = [
  'Comment',
  'Preview',
  'confirmMessage',
  '$scope',
  'compileHTML',
  '$rootScope'
];


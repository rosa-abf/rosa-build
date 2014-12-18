CommentsController = (Comment, Preview, confirmMessage, $compile, $scope) ->

  inlineCommentParams = {}
  list                = null
  new_inline_form     = $('.new_inline_comment_form.hidden')

  compileHTML = (data) ->
    template = angular.element(data)
    linkFn   = $compile(template)
    linkFn($scope)

  setInlineCommentParams = (params) ->
    inlineCommentParams = params

  findInlineComments = (params) ->
    if params.in_reply
      $('#comment'+params.in_reply).parents('tr').find('td .line-comment:last')
    else
      $()

  vm = this

  vm.isDisabledNewInlineCommentButton = ->
    vm.processing || vm.new_inline_body is '' || !vm.new_inline_body

  vm.isDisabledNewCommentButton = ->
    vm.processing || vm.new_body is '' || !vm.new_body

  vm.previewBody = (id) ->
    if id is 'new-comment'
      body = vm.new_body
    else if id is 'new-inline-comment'
      body = vm.new_inline_body
    else
      body = $('#'+id+'-body').val()

    if body is '' or !body
      vm.preview_body = ''
      return false
    if body is Preview.old_text
      return false

    return false if vm.processing
    vm.processing = true
    Preview.old_text = ''

    promise = Preview.get_preview(vm.project, body)
    promise.success( (response) ->
      vm.preview_body  = response
      Preview.old_text = body
    ).error( (response) ->
      vm.preview_body = 'Error :('
    )

    vm.processing = false
    false

  vm.toggleEditForm = (id) ->
    $('.open-comment').addClass('hidden')
    form = $('.open-comment.comment-'+id)
    if form.length is 1
      form.removeClass('hidden')
      true
    else
      false

  vm.add = ->
    vm.processing = true
    promise = Comment.add(vm.project, vm.commentable, vm.new_body)
    promise.then (response) ->
      element = compileHTML(response.data.html)
      list.append(element)

      vm.new_body = ''
      location.hash = "#comment" + response.data.id;
      vm.processing = false

    false

  vm.remove = (id) ->
    return false unless confirmMessage.show()
    vm.processing = true
    promise = Comment.remove(vm.project, vm.commentable, id)
    promise.then () ->
      $('#comment'+id).remove()
      vm.processing = false

    false

  vm.update = (id) ->
    vm.processing = true
    promise = Comment.update(vm.project, vm.commentable, id)
    promise.then (response) ->
      form = $('#comment'+id+ ' .md_and_cm.cm-s-default').html(response.data.body)

      vm.processing = false
      form = $('.open-comment.comment-'+id)
      if form.length is 1
        form.addClass('hidden')
        return true
      else
        return false

  vm.showInlineForm = (params = {}) ->
    line_comments = findInlineComments(params)
    return false if line_comments.count is 0

    vm.new_inline_body = null
    vm.hideInlineForm()
    setInlineCommentParams(params)

    new_form = new_inline_form.html()
    new_form = compileHTML(new_form)
    line_comments.append(new_form)
    line_comments.find('#new_inline_comment').addClass('cloned')
    true

  vm.hideInlineForm = ->
    $('#new_inline_comment.cloned').remove()
    inlineCommentParams = {}
    false

  vm.hideInlineCommentButton = (params = {}) ->
    _.isEqual(inlineCommentParams, params)

  vm.addInline = ->
    inline_comments = findInlineComments(inlineCommentParams)
    return false if inline_comments.count is 0

    vm.processing = true
    promise = Comment.addInline(vm.project, vm.commentable, vm.new_inline_body, inlineCommentParams)
    promise.then (response) ->
      element = compileHTML(response.data.html)
      vm.hideInlineForm()
      inline_comments.append(element)

      vm.new_inline_body = ''
      location.hash = "#comment" + response.data.id;
      vm.processing = false

    false

  vm.init = (project, commentable = {}) ->
    vm.project     = project
    vm.commentable = commentable
    vm.processing  = false
    vm.k = 10
    if commentable.kind is 'issue'
      list = $('#comments_list')
    else if commentable.kind is 'pull'
      list = $('#pull-activity')
    else
      list = $()
    true
  true

angular
  .module("RosaABF")
  .controller "CommentsController", CommentsController

CommentsController.$inject = [
                               'Comment'
                               'Preview'
                               'confirmMessage'
                               '$compile'
                               '$scope'
                             ]

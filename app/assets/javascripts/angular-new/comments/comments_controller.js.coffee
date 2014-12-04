CommentsController = (Comment, Preview, confirmMessage, $compile, $scope) ->

  comments_list = $('#comments_list')

  vm = this

  vm.isDisabledNewCommentButton = ->
    vm.processing || vm.new_body is '' || !vm.new_body

  vm.previewBody = (id) ->
    if id is 'new-comment'
      body = vm.new_body
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

  vm.add = () ->
    new_id = null
    vm.processing = true
    promise = Comment.add(vm.project, vm.commentable, vm.new_body)
    promise.then (response) ->
      template = angular.element(response.data)
      linkFn   = $compile(template)
      element  = linkFn($scope)
      comments_list.append(element)

      vm.new_body = ''
      new_id = comments_list.find('div.panel.panel-default:last').attr('id')
      location.hash = "#" + new_id;
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

  vm.init = (project, commentable = {}) ->
    vm.project     = project
    vm.commentable = commentable
    vm.processing  = false

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

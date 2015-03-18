commentService = ($http) ->
  getPath = (kind, project, commentable, id) ->
    if (kind is 'remove' or kind is 'update') and commentable.kind is 'issue'
      return Routes.project_issue_comment_path(project, commentable.id, id)
    else if kind is 'add' and commentable.kind is 'issue'
      return Routes.project_issue_comments_path(project, commentable.id)
    else if (kind is 'remove' or kind is 'update') and commentable.kind is 'commit'
      return Routes.project_commit_comment_path(project, commentable.id, id)
    else if kind is 'add' and commentable.kind is 'commit'
      return Routes.project_commit_comments_path(project, commentable.id)

  {
    add: (project, commentable, body) ->
      path = getPath('add', project, commentable)
      params = { comment: { body:  body }}
      $http.post(path, params)

    addInline: (project, commentable, body, params) ->
      path = getPath('add', project, commentable)
      params = {
                 comment: { body:  body },
                 in_reply: params.in_reply,
                 line:     params.line,
                 path:     params.path
               }
      $http.post(path, params)

    update: (project, commentable, id) ->
      path = getPath('update', project, commentable, id)
      params = { comment: { body:  $('#comment-'+id+'-body').val() }}
      $http.patch(path, params)

    remove: (project, commentable, id) ->
      path = getPath('remove', project, commentable, id)
      $http.delete(path)
  }

angular
  .module("RosaABF")
  .factory "Comment", commentService

commentService.$inject = ['$http']

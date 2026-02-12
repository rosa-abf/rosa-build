var commentService = function($http) {

  var getPath = function(kind, project, commentable, id) {
    if (commentable.kind === 'issue' || commentable.kind === 'pull') {
      if (kind === 'remove' || kind === 'update') {
        return Routes.project_issue_comment_path(project, commentable.id, id);
      } else if (kind === 'add') {
        return Routes.project_issue_comments_path(project, commentable.id);
      }
    } else if (commentable.kind === 'commit') {
      if (kind === 'remove' || kind === 'update') {
        return Routes.project_commit_comment_path(project, commentable.id, id);
      } else if (kind === 'add') {
        return Routes.project_commit_comments_path(project, commentable.id);
      }
    }
  };

  return {
    add: function(project, commentable, body) {
      var path = getPath('add', project, commentable);
      var params = { comment: { body: body } };
      return $http.post(path, params);
    },

    addInline: function(project, commentable, body, params) {
      var path = getPath('add', project, commentable);
      var params = {
        comment: { body: body },
        in_reply: params.in_reply,
        line: params.line,
        path: params.path
      };
      return $http.post(path, params);
    },

    update: function(project, commentable, id) {
      var path = getPath('update', project, commentable, id);
      var params = { comment: { body: $('#comment-' + id + '-body').val() } };
      return $http.patch(path, params);
    },

    remove: function(project, commentable, id) {
      var path = getPath('remove', project, commentable, id);
      return $http.delete(path);
    }
  };
};

angular
  .module("RosaABF")
  .factory("Comment", commentService);

commentService.$inject = ['$http'];

json.id @comment.id
json.html render partial: 'projects/comments/line_comment.html.slim'
json.message t('flash.comment.saved')

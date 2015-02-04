json.(@issue, :title)
json.body markdown(@issue.body)

json.labels do
  json.partial! 'labels', project: @project, issue: @issue
end

json.status do
  json.partial! 'status', issue: @issue
end


#json.updated_at     @issue.updated_at
#json.updated_at_utc @issue.updated_at.strftime('%Y-%m-%d %H:%M:%S UTC')

if @issue.assignee
  json.assignee do
    json.path     user_path(@issue.assignee)
    json.image    avatar_url(@issue.assignee)
    json.fullname @issue.assignee.fullname
  end
else
  json.assignee do
  end
end

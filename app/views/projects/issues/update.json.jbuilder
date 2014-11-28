json.(@issue, :title, :status)
json.body markdown(@issue.body)

json.labels do
  json.array!(@issue.labels) do |label|
    json.name  label.name
  end
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

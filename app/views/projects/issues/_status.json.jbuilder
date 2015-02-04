json.name issue.status

if issue.closer
  json.closer do
    json.path     user_path(@issue.closer)
    json.image    avatar_url(@issue.closer)
    json.fullname @issue.closer.fullname
  end
else
  json.closer do
  end
end

if issue.closed_at
  json.closed_at     issue.closed_at
  json.closed_at_utc issue.closed_at.strftime('%Y-%m-%d %H:%M:%S UTC')
end

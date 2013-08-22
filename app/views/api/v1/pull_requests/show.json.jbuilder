json.pull_request do
  json.partial! 'pull', :pull => @pull
  json.body @pull.body
  json.closed_at @pull.issue.closed_at.to_i if @pull.merged? || @pull.closed?

  if @pull.issue.closer
    json.closed_by do
      json.(@pull.issue.closer, :id, :name, :uname)
    end
    json.merged_by do
      json.(@pull.issue.closer, :id, :name, :uname)
    end if @pull.merged?
  end

  json.created_at @pull.issue.created_at.to_i
  json.updated_at @pull.issue.updated_at.to_i
end

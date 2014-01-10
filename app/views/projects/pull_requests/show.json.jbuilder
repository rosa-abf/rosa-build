json.pull_request do

  json.number @pull.serial_id
  json.(@pull, :status)
  json.to_ref do
    json.ref @pull.to_ref
    json.sha @pull.to_commit.try(:id)
    json.project do
      json.(@pull.to_project, :id, :name)
      json.owner_uname @pull.to_project.owner.uname
    end
  end
  json.from_ref do
    json.ref @pull.from_ref
    json.sha @pull.from_commit.try(:id)
    json.project do
      json.(@pull.from_project, :id, :name)
      json.owner_uname @pull.to_project.owner.uname
    end
  end

  json.owner do
    json.(@pull.user, :id, :name, :uname)
  end

  json.assignee do
    json.(@pull.issue.assignee, :id, :name, :uname)
  end if @pull.issue.assignee
  json.mergeable @pull.can_merging?
  json.merged_at @pull.issue.closed_at.to_i if @pull.merged?

  json.closed_at @pull.issue.closed_at.to_i if @pull.merged? || @pull.closed?
  if @pull.issue.closer
    json.closed_by do
      json.(@pull.issue.closer, :id, :name, :uname)
    end
    json.merged_by do
      json.(@pull.issue.closer, :id, :name, :uname)
    end if @pull.merged?
  end
end

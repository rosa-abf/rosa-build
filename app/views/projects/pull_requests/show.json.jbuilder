json.pull_request do

  json.number @pull.serial_id
  json.(@pull, :status, :updated_at)
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
      json.(@pull.from_project, :id, :name) if @pull.from_project.present?
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

  if @pull.merged?
    json.merged_at     @pull.issue.closed_at
    json.merged_at_utc @pull.issue.closed_at.strftime('%Y-%m-%d %H:%M:%S UTC')
  end

  if @pull.closed?
    json.closed_at     @pull.issue.closed_at
    json.closed_at_utc @pull.issue.closed_at.strftime('%Y-%m-%d %H:%M:%S UTC')
  end

  if @pull.issue.closer
    json.closed_by do
      json.(@pull.issue.closer, :uname, :fullname)
      json.path  user_path(@pull.issue.closer)
      json.image avatar_url(@pull.issue.closer)
    end
    json.merged_by do
      json.(@pull.issue.closer, :uname, :fullname)
      json.path  user_path(@pull.issue.closer)
      json.image avatar_url(@pull.issue.closer)
    end if @pull.merged?
  end

  commits_count = @commits.count.to_s
  commits_count << '+' if @total_commits > @commits.count

  json.stats_count @stats.count
  json.commits_count commits_count
end

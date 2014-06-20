class PublishTaskManagerJob
  @queue = :middle

  def self.perform
    regenerate_metadata_for_software_center
    resign_repositories
    regenerate_metadata
    AbfWorkerService::Rpm.publish!
  end

  protected

  def regenerate_metadata_for_software_center
    Platform.main.waiting_for_regeneration.each do |platform|
      AbfWorkerService::PlatformMetadata.new(platform).regenerate!
    end
  end

  def resign_repositories
    statuses = RepositoryStatus.platform_ready.
      for_resign.includes(repository: :platform).readonly(false)

    statuses.each do |repository_status|
      AbfWorkerService::Repository.new(repository_status.repository).resign!(repository_status)
    end
  end

  def regenerate_metadata
    statuses = RepositoryStatus.platform_ready.
      for_regeneration.includes(repository: :platform).readonly(false)

    statuses.each do |repository_status|
      AbfWorkerService::RepositoryMetadata.new(repository_status).regenerate!
    end
  end


end
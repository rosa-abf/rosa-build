class DestroyProjectFromRepositoryJob
  @queue = :middle

  def self.perform(project_id, repository_id)
    project     = Project.find(project_id)
    repository  = Repository.find(repository_id)

    service = AbfWorkerService::Repository.new(repository)
    service.destroy_project!(project)
  end

end

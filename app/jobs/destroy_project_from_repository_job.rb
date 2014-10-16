class DestroyProjectFromRepositoryJob

  def self.perform(project, repository)
    service = AbfWorkerService::Repository.new(repository)
    service.destroy_project!(project)
  end

end

class BuildListsPublishTaskManagerJob
  @queue = :hook

  def self.perform
    AbfWorker::BuildListsPublishTaskManager.new.run
  end

end

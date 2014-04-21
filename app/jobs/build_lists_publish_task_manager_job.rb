class BuildListsPublishTaskManagerJob
  @queue = :middle

  def self.perform
    AbfWorker::BuildListsPublishTaskManager.new.run
  end

end

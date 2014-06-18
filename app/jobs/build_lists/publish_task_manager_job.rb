module BuildLists
  class PublishTaskManagerJob
    @queue = :middle

    def self.perform
      AbfWorker::BuildListsPublishTaskManager.new.run
    end

  end
end
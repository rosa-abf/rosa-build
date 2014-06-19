module BuildLists
  class CreateContainerJob
    @queue = :middle

    def self.perform(build_list_id)
      build_list  = BuildList.find(build_list_id)
      container   = AbfWorkerService::Container.new(build_list)
      container.create!
    end

  end
end
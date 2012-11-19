module AbfWorker
  class IsoWorkerObserver
    @queue = :iso_worker_observer

    def self.perform(options)
      status = options['status'].to_i
      pbl = ProductBuildList.find options['id']
      pbl.status = status if pbl.status != ProductBuildList::BUILD_CANCELED
      pbl.results = options['results'] if status != ProductBuildList::BUILD_STARTED
      pbl.save!
    end

  end
end